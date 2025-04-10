local addonName, WR = ...

-- ResourceForecast module for predicting and visualizing resource changes
local ResourceForecast = {}
WR.UI.ResourceForecast = ResourceForecast

-- Import commonly used global functions for performance
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitClass = UnitClass
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellInfo = GetSpellInfo
local GetSpellDescription = GetSpellDescription
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local table_insert = table.insert
local table_sort = table.sort

-- Module state variables
local playerClass, playerSpec, playerLevel
local primaryResourceType
local resourceName
local forecastWindow = 10 -- Seconds to forecast
local forecastPoints = 40 -- Number of data points for graph
local forecastInterval = forecastWindow / forecastPoints -- Time between points
local resourceChangeCache = {} -- Cache of resource changes per ability
local resourceData = { -- Storage for resource tracking
    current = 0,
    max = 100,
    regenRate = 0,
    predictions = {},
    abilityPoints = {},
    historyPoints = {}
}
local graphUpdateNeeded = true
local lastResourceValue = 0
local lastUpdateTime = 0
local historySeconds = 10 -- How many seconds of history to keep
local configuration = {
    enabled = true,
    scale = 1.0,
    position = { x = 400, y = 0 },
    showHistory = true,
    detailedTooltips = true,
    graphHeight = 100,
    graphWidth = 300,
    alpha = 0.9,
    backgroundAlpha = 0.3,
    colorizeByClass = true,
    displayMode = "overlay", -- "overlay" or "window"
    showAbilityIcons = true,
    showLegend = true,
    advancedPrediction = true,
    updateFrequency = 0.25
}

-- Color definitions
local colors = {
    background = { r = 0.1, g = 0.1, b = 0.1, a = 0.3 },
    border = { r = 0.7, g = 0.7, b = 0.7, a = 0.7 },
    grid = { r = 0.3, g = 0.3, b = 0.3, a = 0.3 },
    text = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
    resourceLine = { r = 0.2, g = 0.6, b = 1.0, a = 0.8 },
    historyLine = { r = 0.4, g = 0.4, b = 0.4, a = 0.5 },
    maxLine = { r = 0.8, g = 0.1, b = 0.1, a = 0.3 },
    generator = { r = 0.1, g = 0.8, b = 0.1, a = 0.8 },
    spender = { r = 0.8, g = 0.1, b = 0.1, a = 0.8 },
    neutral = { r = 0.7, g = 0.7, b = 0.1, a = 0.8 }
}

-- Graph element references
local frame
local graphFrame
local canvas
local tooltipFrame
local legend
local timeMarkers = {}
local valueMarkers = {}
local graphLines = {}
local abilityIcons = {}
local historyPoints = {}
local maxLine

-- Initialize the module
function ResourceForecast:Initialize()
    -- Get player information
    playerClass = select(2, UnitClass("player"))
    playerSpec = GetSpecialization()
    playerLevel = UnitLevel("player")
    
    -- Determine resource type based on class/spec
    self:DetermineResourceType()
    
    -- Load saved configuration
    self:LoadConfiguration()
    
    -- Create UI
    self:CreateFrames()
    
    -- Register events
    self:RegisterEvents()
    
    -- Initialize resource data
    self:UpdateResourceInfo()
    
    -- Start update cycle
    self:StartUpdates()
    
    WR:Debug("ResourceForecast module initialized")
end

-- Determine resource type based on player class and spec
function ResourceForecast:DetermineResourceType()
    if playerClass == "WARRIOR" then
        primaryResourceType = Enum.PowerType.Rage
        resourceName = "Rage"
    elseif playerClass == "PALADIN" then
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "HUNTER" then
        primaryResourceType = Enum.PowerType.Focus
        resourceName = "Focus"
    elseif playerClass == "ROGUE" then
        primaryResourceType = Enum.PowerType.Energy
        resourceName = "Energy"
    elseif playerClass == "PRIEST" then
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "DEATHKNIGHT" then
        primaryResourceType = Enum.PowerType.RunicPower
        resourceName = "Runic Power"
    elseif playerClass == "SHAMAN" then
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "MAGE" then
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "WARLOCK" then
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    elseif playerClass == "MONK" then
        if playerSpec == 3 then -- Windwalker
            primaryResourceType = Enum.PowerType.Energy
            resourceName = "Energy"
        else
            primaryResourceType = Enum.PowerType.Mana
            resourceName = "Mana"
        end
    elseif playerClass == "DRUID" then
        if playerSpec == 2 then -- Feral
            primaryResourceType = Enum.PowerType.Energy
            resourceName = "Energy"
        elseif playerSpec == 3 then -- Guardian
            primaryResourceType = Enum.PowerType.Rage
            resourceName = "Rage"
        else
            primaryResourceType = Enum.PowerType.Mana
            resourceName = "Mana"
        end
    elseif playerClass == "DEMONHUNTER" then
        primaryResourceType = Enum.PowerType.Fury
        resourceName = "Fury"
    elseif playerClass == "EVOKER" then
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    else
        -- Default to mana if we can't determine
        primaryResourceType = Enum.PowerType.Mana
        resourceName = "Mana"
    end
end

-- Load saved configuration
function ResourceForecast:LoadConfiguration()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.ResourceForecast then
        -- Load saved settings
        for key, value in pairs(WindrunnerRotationsDB.ResourceForecast) do
            if configuration[key] ~= nil then
                configuration[key] = value
            end
        end
    end
end

-- Save configuration
function ResourceForecast:SaveConfiguration()
    -- Initialize DB if needed
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    -- Save settings
    WindrunnerRotationsDB.ResourceForecast = {}
    for key, value in pairs(configuration) do
        WindrunnerRotationsDB.ResourceForecast[key] = value
    end
end

-- Register events
function ResourceForecast:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame.obj = self
    
    -- Register for events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("UNIT_POWER_FREQUENT")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_MAXPOWER")
    
    -- Set event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        local obj = self.obj
        
        if event == "PLAYER_ENTERING_WORLD" then
            obj:UpdatePlayerInfo()
            obj:UpdateResourceInfo()
            graphUpdateNeeded = true
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            local unit = ...
            if unit == "player" then
                obj:UpdatePlayerInfo()
                obj:DetermineResourceType()
                obj:UpdateResourceInfo()
                obj:UpdateGraphTitle()
                graphUpdateNeeded = true
            end
        elseif event == "UNIT_POWER_FREQUENT" then
            local unit, powerType = ...
            if unit == "player" and obj:GetPowerTypeKey(powerType) == obj:GetPowerTypeKey(primaryResourceType) then
                obj:UpdateResourceInfo()
                graphUpdateNeeded = true
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            if unit == "player" then
                obj:RecordSpellCast(spellID)
                graphUpdateNeeded = true
            end
        elseif event == "UNIT_MAXPOWER" then
            local unit, powerType = ...
            if unit == "player" and obj:GetPowerTypeKey(powerType) == obj:GetPowerTypeKey(primaryResourceType) then
                obj:UpdateResourceInfo()
                graphUpdateNeeded = true
            end
        end
    end)
    
    self.eventFrame = eventFrame
end

-- Convert power type to key string for comparison
function ResourceForecast:GetPowerTypeKey(powerType)
    if type(powerType) == "string" then
        return powerType:upper()
    else
        -- Convert enum to string
        return tostring(powerType)
    end
end

-- Update player information
function ResourceForecast:UpdatePlayerInfo()
    playerClass = select(2, UnitClass("player"))
    playerSpec = GetSpecialization()
    playerLevel = UnitLevel("player")
}

-- Update resource information
function ResourceForecast:UpdateResourceInfo()
    local current = UnitPower("player", primaryResourceType)
    local max = UnitPowerMax("player", primaryResourceType)
    
    -- Record for history
    if current ~= lastResourceValue or GetTime() - lastUpdateTime > 1 then
        table_insert(resourceData.historyPoints, {
            time = GetTime(),
            value = current
        })
        lastResourceValue = current
        lastUpdateTime = GetTime()
        
        -- Trim old history points
        local cutoffTime = GetTime() - historySeconds
        while resourceData.historyPoints[1] and resourceData.historyPoints[1].time < cutoffTime do
            table.remove(resourceData.historyPoints, 1)
        end
    end
    
    -- Update current values
    resourceData.current = current
    resourceData.max = max
    
    -- Calculate regeneration rate
    if primaryResourceType == Enum.PowerType.Mana or primaryResourceType == Enum.PowerType.Energy then
        resourceData.regenRate = GetPowerRegenForPowerType(primaryResourceType) or 0
    else
        resourceData.regenRate = 0
    end
    
    -- Generate forecast with available data
    self:GenerateForecast()
}

-- Generate resource forecast
function ResourceForecast:GenerateForecast()
    -- Clear old predictions
    resourceData.predictions = {}
    
    -- Get current rotation information if available
    local abilities = self:GetUpcomingAbilities()
    
    -- Start with current value
    local currentResource = resourceData.current
    local regenRate = resourceData.regenRate
    local maxResource = resourceData.max
    local lastTime = 0
    
    -- Add current point
    table_insert(resourceData.predictions, {
        time = 0,
        value = currentResource,
        type = "current"
    })
    
    -- If no abilities, just predict based on regeneration
    if not abilities or #abilities == 0 then
        for i = 1, forecastPoints do
            local time = i * forecastInterval
            local predictedValue = math_min(maxResource, currentResource + regenRate * time)
            
            table_insert(resourceData.predictions, {
                time = time,
                value = predictedValue,
                type = "regen"
            })
        end
        
        return
    end
    
    -- Process each ability in sequence
    resourceData.abilityPoints = {}
    local timeSoFar = 0
    
    for i, ability in ipairs(abilities) do
        -- Estimate resource at this point including regen
        local abilityTime = ability.time or (timeSoFar + (i == 1 and 0 or 1.5))
        local regenAmount = regenRate * (abilityTime - timeSoFar)
        local resourceBeforeAbility = math_min(maxResource, currentResource + regenAmount)
        
        -- Calculate resource change from ability
        local resourceChange = self:GetResourceChangeForSpell(ability.id) or 0
        
        -- Add prediction points up to this ability
        if abilityTime > lastTime + forecastInterval then
            for t = lastTime + forecastInterval, abilityTime - forecastInterval, forecastInterval do
                local regenSoFar = regenRate * (t - lastTime)
                local predictedValue = math_min(maxResource, currentResource + regenSoFar)
                
                table_insert(resourceData.predictions, {
                    time = t,
                    value = predictedValue,
                    type = "regen"
                })
            end
        end
        
        -- Store ability info
        local resourceAfterAbility = math_max(0, math_min(maxResource, resourceBeforeAbility + resourceChange))
        
        table_insert(resourceData.abilityPoints, {
            time = abilityTime,
            resourceBefore = resourceBeforeAbility,
            resourceAfter = resourceAfterAbility,
            resourceChange = resourceChange,
            abilityId = ability.id,
            abilityName = ability.name or GetSpellInfo(ability.id) or "Unknown",
            icon = select(3, GetSpellInfo(ability.id))
        })
        
        -- Add prediction point for after ability
        table_insert(resourceData.predictions, {
            time = abilityTime,
            value = resourceAfterAbility,
            type = resourceChange > 0 and "generator" or (resourceChange < 0 and "spender" or "neutral"),
            abilityId = ability.id
        })
        
        -- Update tracking variables
        currentResource = resourceAfterAbility
        lastTime = abilityTime
        timeSoFar = abilityTime
    end
    
    -- Fill in the rest of the prediction with regeneration
    while lastTime < forecastWindow do
        lastTime = lastTime + forecastInterval
        local regenAmount = regenRate * forecastInterval
        currentResource = math_min(maxResource, currentResource + regenAmount)
        
        table_insert(resourceData.predictions, {
            time = lastTime,
            value = currentResource,
            type = "regen"
        })
    end
}

-- Get upcoming abilities from rotation system
function ResourceForecast:GetUpcomingAbilities()
    if not WR.Rotation or not WR.Rotation.GetUpcomingAbilities then
        return {}
    end
    
    -- Get next 5-7 abilities in the rotation
    return WR.Rotation:GetUpcomingAbilities(7)
}

-- Get resource change for a spell
function ResourceForecast:GetResourceChangeForSpell(spellId)
    -- Check cache first
    if resourceChangeCache[spellId] then
        return resourceChangeCache[spellId]
    end
    
    -- Calculate resource change
    local resourceChange = 0
    
    -- Try to determine from spell description
    local description = GetSpellDescription(spellId) or ""
    
    -- This is a simplistic approach - a real implementation would need more sophistication
    if description:find("generates?%s+(%d+)%s+" .. resourceName:lower()) then
        -- Spell generates resource
        resourceChange = tonumber(description:match("generates?%s+(%d+)%s+" .. resourceName:lower())) or 0
    elseif description:find("costs?%s+(%d+)%s+" .. resourceName:lower()) then
        -- Spell costs resource
        resourceChange = -1 * (tonumber(description:match("costs?%s+(%d+)%s+" .. resourceName:lower())) or 0)
    elseif description:find("(%d+)%s+" .. resourceName:lower()) then
        -- More generic matching
        local amount = tonumber(description:match("(%d+)%s+" .. resourceName:lower())) or 0
        -- Try to determine if it's a cost or generation
        if description:find("spend") or description:find("consume") or description:find("cost") then
            resourceChange = -1 * amount
        elseif description:find("grant") or description:find("generate") or description:find("gain") then
            resourceChange = amount
        end
    end
    
    -- Use class-specific overrides when needed
    resourceChange = self:ApplyClassSpecificResourceRules(spellId, resourceChange)
    
    -- Cache the result
    resourceChangeCache[spellId] = resourceChange
    
    return resourceChange
end

-- Apply class-specific resource rules
function ResourceForecast:ApplyClassSpecificResourceRules(spellId, resourceChange)
    -- Override specific spells based on class knowledge
    if playerClass == "WARRIOR" then
        -- Warrior Rage generators/spenders
        local warriorSpells = {
            [23881] = 8,     -- Bloodthirst (generates 8 Rage)
            [85288] = -30,   -- Raging Blow (costs 30 Rage)
            [1464] = -20,    -- Slam (costs 20 Rage)
            [1719] = 50,     -- Recklessness (generates 50 Rage)
            [6572] = 5,      -- Revenge (generates 5 Rage)
            [20243] = 2,     -- Devastate (generates 2 Rage)
            [12294] = -30,   -- Mortal Strike (costs 30 Rage)
            [1680] = -20,    -- Whirlwind (costs 20 Rage)
        }
        
        if warriorSpells[spellId] then
            return warriorSpells[spellId]
        end
    elseif playerClass == "DRUID" and playerSpec == 2 then
        -- Feral Druid Energy costs
        local feralSpells = {
            [5221] = -35,    -- Shred (costs 35 Energy)
            [1079] = -25,    -- Rip (costs 25 Energy)
            [22568] = -35,   -- Ferocious Bite (costs 35 Energy)
            [22570] = -35,   -- Maim (costs 35 Energy)
            [1822] = -35,    -- Rake (costs 35 Energy)
            [106830] = -30,  -- Thrash (costs 30 Energy)
            [106785] = -30,  -- Swipe (costs 30 Energy)
            [5217] = 60,     -- Tiger's Fury (generates 60 Energy)
        }
        
        if feralSpells[spellId] then
            return feralSpells[spellId]
        end
    elseif playerClass == "ROGUE" then
        -- Rogue Energy costs
        local rogueSpells = {
            [193315] = -35,  -- Sinister Strike (costs 35 Energy)
            [1752] = -40,    -- Sinister Strike (costs 40 Energy)
            [2098] = -35,    -- Eviscerate (costs 35 Energy)
            [185311] = -30,  -- Crimson Vial (costs 30 Energy)
            [53] = -40,      -- Backstab (costs 40 Energy)
            [8676] = -40,    -- Ambush (costs 40 Energy)
            [196819] = -30,  -- Dispatch (costs 30 Energy)
            [13877] = 50,    -- Blade Flurry (reduces energy regen)
            [13750] = 50,    -- Adrenaline Rush (increases energy regen)
        }
        
        if rogueSpells[spellId] then
            return rogueSpells[spellId]
        end
    elseif playerClass == "HUNTER" then
        -- Hunter Focus costs
        local hunterSpells = {
            [34026] = -30,   -- Kill Command (costs 30 Focus)
            [19434] = -35,   -- Aimed Shot (costs 35 Focus) 
            [56641] = -10,   -- Steady Shot (generates 10 Focus)
            [257044] = -20,  -- Rapid Fire (costs 20 Focus)
            [185358] = -40,  -- Arcane Shot (costs 40 Focus)
            [2643] = -15,    -- Multi-Shot (costs 15 Focus)
            [187698] = -20,  -- Tar Trap (costs 20 Focus)
            [186387] = 50,   -- Aspect of the Pack (increases Focus regen)
        }
        
        if hunterSpells[spellId] then
            return hunterSpells[spellId]
        end
    end
    
    -- If no override, return the original value
    return resourceChange
end

-- Record a spell cast for resource prediction improvements
function ResourceForecast:RecordSpellCast(spellId)
    -- In a real implementation, this would analyze actual resource changes
    -- and improve the accuracy of future predictions
    -- 
    -- For now, we'll just trigger a forecast update
    graphUpdateNeeded = true
}

-- Create UI frames
function ResourceForecast:CreateFrames()
    -- Main frame
    frame = CreateFrame("Frame", "WRResourceForecastFrame", UIParent)
    frame:SetSize(configuration.graphWidth + 20, configuration.graphHeight + 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", configuration.position.x, configuration.position.y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetScale(configuration.scale)
    frame:SetAlpha(configuration.alpha)
    
    -- Make it movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        -- Update position
        local scale = self:GetScale()
        local x, y = self:GetCenter()
        x = x * scale - GetScreenWidth()/2
        y = y * scale - GetScreenHeight()/2
        
        configuration.position.x = math_floor(x + 0.5)
        configuration.position.y = math_floor(y + 0.5)
        
        ResourceForecast:SaveConfiguration()
    end)
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(colors.background.r, colors.background.g, colors.background.b, colors.background.a)
    
    -- Border
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Use class color for border if enabled
    if configuration.colorizeByClass then
        local classColor = RAID_CLASS_COLORS[playerClass]
        if classColor then
            frame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1.0)
        else
            frame:SetBackdropBorderColor(colors.border.r, colors.border.g, colors.border.b, colors.border.a)
        end
    else
        frame:SetBackdropBorderColor(colors.border.r, colors.border.g, colors.border.b, colors.border.a)
    end
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText(resourceName .. " Forecast")
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    
    -- Graph frame
    graphFrame = CreateFrame("Frame", nil, frame)
    graphFrame:SetSize(configuration.graphWidth, configuration.graphHeight)
    graphFrame:SetPoint("TOP", title, "BOTTOM", 0, -5)
    
    -- Canvas for drawing the graph
    canvas = graphFrame:CreateTexture(nil, "ARTWORK")
    canvas:SetAllPoints()
    canvas:SetColorTexture(0, 0, 0, 0.1) -- Transparent background
    
    -- Create graph grid
    self:CreateGraphGrid()
    
    -- Create time markers (x-axis)
    self:CreateTimeMarkers()
    
    -- Create value markers (y-axis)
    self:CreateValueMarkers()
    
    -- Create max resource line
    maxLine = graphFrame:CreateTexture(nil, "ARTWORK")
    maxLine:SetHeight(2)
    maxLine:SetColorTexture(colors.maxLine.r, colors.maxLine.g, colors.maxLine.b, colors.maxLine.a)
    
    -- Create graph lines
    for i = 1, forecastPoints + 1 do
        local line = graphFrame:CreateTexture(nil, "ARTWORK")
        line:SetHeight(2)
        line:SetColorTexture(colors.resourceLine.r, colors.resourceLine.g, colors.resourceLine.b, colors.resourceLine.a)
        line:Hide()
        
        table_insert(graphLines, line)
    end
    
    -- Create history point lines
    for i = 1, historySeconds * 4 do -- 4 points per second
        local point = graphFrame:CreateTexture(nil, "ARTWORK")
        point:SetSize(3, 3)
        point:SetColorTexture(colors.historyLine.r, colors.historyLine.g, colors.historyLine.b, colors.historyLine.a)
        point:Hide()
        
        table_insert(historyPoints, point)
    end
    
    -- Create ability icons
    for i = 1, 10 do -- Max number of ability markers
        local icon = CreateFrame("Frame", nil, graphFrame)
        icon:SetSize(20, 20)
        icon:Hide()
        
        -- Icon texture
        local texture = icon:CreateTexture(nil, "ARTWORK")
        texture:SetAllPoints()
        texture:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Trim icon borders
        
        -- Border
        local border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
        border:SetAllPoints()
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        border:SetBackdropBorderColor(0.7, 0.7, 0.7, 0.7)
        
        -- Tooltip
        icon:SetScript("OnEnter", function(self)
            if not self.data then return end
            
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.data.abilityId)
            
            if configuration.detailedTooltips then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(self.data.resourceChange > 0 
                    and "Generates " .. math_abs(self.data.resourceChange) .. " " .. resourceName
                    or "Costs " .. math_abs(self.data.resourceChange) .. " " .. resourceName, 
                    1, 1, 1)
                GameTooltip:AddLine("Resource before: " .. math_floor(self.data.resourceBefore), 1, 1, 1)
                GameTooltip:AddLine("Resource after: " .. math_floor(self.data.resourceAfter), 1, 1, 1)
                GameTooltip:AddLine("Time: +" .. string.format("%.1f", self.data.time) .. "s", 1, 1, 1)
            end
            
            GameTooltip:Show()
        end)
        
        icon:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- Store references
        abilityIcons[i] = {
            frame = icon,
            texture = texture,
            border = border
        }
    end
    
    -- Create tooltip frame for hovering over graph points
    tooltipFrame = CreateFrame("Frame", nil, graphFrame)
    tooltipFrame:SetAllPoints()
    tooltipFrame:EnableMouse(true)
    tooltipFrame:SetScript("OnEnter", function(self)
        -- Show tooltip with current resource values
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:AddLine(resourceName .. " Forecast")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Current: " .. math_floor(resourceData.current) .. "/" .. resourceData.max .. " (" .. 
                          math_floor(resourceData.current / resourceData.max * 100) .. "%)")
        
        if resourceData.regenRate > 0 then
            GameTooltip:AddLine("Regeneration: " .. string.format("%.1f", resourceData.regenRate) .. " per second")
        end
        
        if #resourceData.abilityPoints > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Upcoming Abilities:")
            for i = 1, math.min(5, #resourceData.abilityPoints) do
                local ability = resourceData.abilityPoints[i]
                local changeText = ability.resourceChange > 0 
                    and "(+" .. math_floor(ability.resourceChange) .. ")" 
                    or "(" .. math_floor(ability.resourceChange) .. ")"
                GameTooltip:AddLine(string.format("%.1fs: %s %s", ability.time, ability.abilityName, changeText))
            end
        end
        
        GameTooltip:Show()
    end)
    
    tooltipFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Create legend if enabled
    if configuration.showLegend then
        self:CreateLegend()
    end
    
    -- Set initial visibility
    if not configuration.enabled then
        frame:Hide()
    end
    
    -- Store frame references
    self.frame = frame
    self.graphFrame = graphFrame
    self.title = title
}

-- Create grid for graph
function ResourceForecast:CreateGraphGrid()
    -- Horizontal grid lines (25%, 50%, 75%)
    for i = 1, 3 do
        local y = configuration.graphHeight * i / 4
        local line = graphFrame:CreateTexture(nil, "BACKGROUND")
        line:SetSize(configuration.graphWidth, 1)
        line:SetPoint("TOPLEFT", graphFrame, "TOPLEFT", 0, -y)
        line:SetColorTexture(colors.grid.r, colors.grid.g, colors.grid.b, colors.grid.a)
    end
    
    -- Vertical grid lines (every 2 seconds)
    for i = 1, forecastWindow / 2 - 1 do
        local x = configuration.graphWidth * (i * 2) / forecastWindow
        local line = graphFrame:CreateTexture(nil, "BACKGROUND")
        line:SetSize(1, configuration.graphHeight)
        line:SetPoint("TOPLEFT", graphFrame, "TOPLEFT", x, 0)
        line:SetColorTexture(colors.grid.r, colors.grid.g, colors.grid.b, colors.grid.a)
    end
}

-- Create time markers for x-axis
function ResourceForecast:CreateTimeMarkers()
    -- Create markers every 2 seconds
    for i = 0, forecastWindow / 2 do
        local marker = graphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        marker:SetPoint("TOP", graphFrame, "BOTTOMLEFT", 
                       configuration.graphWidth * (i * 2) / forecastWindow, 2)
        marker:SetText("+" .. i * 2 .. "s")
        marker:SetTextColor(colors.text.r, colors.text.g, colors.text.b, colors.text.a)
        
        table_insert(timeMarkers, marker)
    end
}

-- Create value markers for y-axis
function ResourceForecast:CreateValueMarkers()
    -- Create markers at 0%, 25%, 50%, 75%, 100%
    for i = 0, 4 do
        local marker = graphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        marker:SetPoint("RIGHT", graphFrame, "TOPLEFT", 
                       -2, -configuration.graphHeight * i / 4)
        marker:SetText(i * 25 .. "%")
        marker:SetTextColor(colors.text.r, colors.text.g, colors.text.b, colors.text.a)
        
        table_insert(valueMarkers, marker)
    end
}

-- Create legend for graph colors
function ResourceForecast:CreateLegend()
    legend = CreateFrame("Frame", nil, frame)
    legend:SetSize(configuration.graphWidth, 20)
    legend:SetPoint("TOP", graphFrame, "BOTTOM", 0, -15)
    
    -- History line
    local historyIcon = legend:CreateTexture(nil, "ARTWORK")
    historyIcon:SetSize(10, 2)
    historyIcon:SetPoint("LEFT", legend, "LEFT", 5, 0)
    historyIcon:SetColorTexture(colors.historyLine.r, colors.historyLine.g, colors.historyLine.b, 1)
    
    local historyText = legend:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    historyText:SetPoint("LEFT", historyIcon, "RIGHT", 2, 0)
    historyText:SetText("History")
    historyText:SetTextColor(1, 1, 1, 1)
    
    -- Prediction line
    local predictionIcon = legend:CreateTexture(nil, "ARTWORK")
    predictionIcon:SetSize(10, 2)
    predictionIcon:SetPoint("LEFT", historyText, "RIGHT", 10, 0)
    predictionIcon:SetColorTexture(colors.resourceLine.r, colors.resourceLine.g, colors.resourceLine.b, 1)
    
    local predictionText = legend:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    predictionText:SetPoint("LEFT", predictionIcon, "RIGHT", 2, 0)
    predictionText:SetText("Prediction")
    predictionText:SetTextColor(1, 1, 1, 1)
    
    -- Generation marker
    local genIcon = legend:CreateTexture(nil, "ARTWORK")
    genIcon:SetSize(10, 2)
    genIcon:SetPoint("LEFT", predictionText, "RIGHT", 10, 0)
    genIcon:SetColorTexture(colors.generator.r, colors.generator.g, colors.generator.b, 1)
    
    local genText = legend:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    genText:SetPoint("LEFT", genIcon, "RIGHT", 2, 0)
    genText:SetText("Generator")
    genText:SetTextColor(1, 1, 1, 1)
    
    -- Spending marker
    local spendIcon = legend:CreateTexture(nil, "ARTWORK")
    spendIcon:SetSize(10, 2)
    spendIcon:SetPoint("LEFT", genText, "RIGHT", 10, 0)
    spendIcon:SetColorTexture(colors.spender.r, colors.spender.g, colors.spender.b, 1)
    
    local spendText = legend:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spendText:SetPoint("LEFT", spendIcon, "RIGHT", 2, 0)
    spendText:SetText("Spender")
    spendText:SetTextColor(1, 1, 1, 1)
}

-- Start update cycle
function ResourceForecast:StartUpdates()
    -- Create update frame with OnUpdate script
    local updateFrame = CreateFrame("Frame")
    updateFrame.sinceLastUpdate = 0
    
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.sinceLastUpdate = self.sinceLastUpdate + elapsed
        
        -- Update at the configured frequency
        if self.sinceLastUpdate >= configuration.updateFrequency then
            -- Only redraw the graph if needed
            if graphUpdateNeeded then
                ResourceForecast:UpdateGraph()
                graphUpdateNeeded = false
            end
            
            self.sinceLastUpdate = 0
        end
    end)
    
    -- Store reference
    self.updateFrame = updateFrame
}

-- Update graph with latest forecast data
function ResourceForecast:UpdateGraph()
    -- Hide all elements first
    for _, line in ipairs(graphLines) do
        line:Hide()
    end
    
    for _, point in ipairs(historyPoints) do
        point:Hide()
    end
    
    for _, icon in ipairs(abilityIcons) do
        icon.frame:Hide()
    end
    
    -- Skip if frame is not visible
    if not frame:IsVisible() then
        return
    end
    
    -- Scale factors
    local xScale = configuration.graphWidth / forecastWindow
    local yScale = configuration.graphHeight / resourceData.max
    
    -- Update value markers to show actual resource values
    for i = 0, 4 do
        local value = resourceData.max * i / 4
        valueMarkers[i+1]:SetText(math_floor(value))
    end
    
    -- Draw max resource line
    maxLine:SetWidth(configuration.graphWidth)
    maxLine:SetPoint("TOPLEFT", graphFrame, "TOPLEFT", 0, 0)
    maxLine:Show()
    
    -- Draw history points if enabled
    if configuration.showHistory and #resourceData.historyPoints > 0 then
        local now = GetTime()
        local historyStart = now - historySeconds
        
        for i, point in ipairs(resourceData.historyPoints) do
            -- Calculate position
            local x = (point.time - historyStart) / historySeconds * configuration.graphWidth
            local y = point.value * yScale
            
            -- Only show if within graph bounds
            if x >= 0 and x <= configuration.graphWidth and i <= #historyPoints then
                historyPoints[i]:ClearAllPoints()
                historyPoints[i]:SetPoint("BOTTOMLEFT", graphFrame, "BOTTOMLEFT", x, y)
                historyPoints[i]:Show()
            end
        end
    end
    
    -- Draw prediction lines
    local predictions = resourceData.predictions
    if #predictions >= 2 then
        for i = 1, #predictions - 1 do
            -- Calculate start and end positions
            local x1 = predictions[i].time * xScale
            local y1 = predictions[i].value * yScale
            local x2 = predictions[i+1].time * xScale
            local y2 = predictions[i+1].value * yScale
            
            -- Calculate line length and angle
            local length = math.sqrt((x2-x1)^2 + (y2-y1)^2)
            local angle = math.atan2(y2-y1, x2-x1)
            
            -- Position and show the line
            graphLines[i]:ClearAllPoints()
            graphLines[i]:SetPoint("BOTTOMLEFT", graphFrame, "BOTTOMLEFT", x1, y1)
            graphLines[i]:SetWidth(length)
            graphLines[i]:SetRotation(angle)
            
            -- Set color based on line type
            if predictions[i+1].type == "generator" then
                graphLines[i]:SetColorTexture(colors.generator.r, colors.generator.g, colors.generator.b, colors.generator.a)
            elseif predictions[i+1].type == "spender" then
                graphLines[i]:SetColorTexture(colors.spender.r, colors.spender.g, colors.spender.b, colors.spender.a)
            else
                graphLines[i]:SetColorTexture(colors.resourceLine.r, colors.resourceLine.g, colors.resourceLine.b, colors.resourceLine.a)
            end
            
            graphLines[i]:Show()
        end
    end
    
    -- Draw ability markers
    if configuration.showAbilityIcons then
        for i, ability in ipairs(resourceData.abilityPoints) do
            if i <= #abilityIcons then
                -- Calculate position
                local x = ability.time * xScale
                local y = ability.resourceAfter * yScale
                
                -- Position and show the icon
                abilityIcons[i].frame:ClearAllPoints()
                abilityIcons[i].frame:SetPoint("CENTER", graphFrame, "BOTTOMLEFT", x, y)
                abilityIcons[i].texture:SetTexture(ability.icon)
                
                -- Set border color based on resource change
                if ability.resourceChange > 0 then
                    abilityIcons[i].border:SetBackdropBorderColor(colors.generator.r, colors.generator.g, colors.generator.b, 1)
                elseif ability.resourceChange < 0 then
                    abilityIcons[i].border:SetBackdropBorderColor(colors.spender.r, colors.spender.g, colors.spender.b, 1)
                else
                    abilityIcons[i].border:SetBackdropBorderColor(colors.neutral.r, colors.neutral.g, colors.neutral.b, 1)
                end
                
                -- Store ability data for tooltips
                abilityIcons[i].frame.data = ability
                
                abilityIcons[i].frame:Show()
            end
        end
    end
}

-- Update graph title
function ResourceForecast:UpdateGraphTitle()
    if not self.title then return end
    
    self.title:SetText(resourceName .. " Forecast")
}

-- Toggle visibility
function ResourceForecast:Toggle()
    if self.frame:IsVisible() then
        self.frame:Hide()
        configuration.enabled = false
    else
        self.frame:Show()
        configuration.enabled = true
        graphUpdateNeeded = true
    end
    
    self:SaveConfiguration()
}

-- Set scale
function ResourceForecast:SetScale(scale)
    scale = math_min(2.0, math_max(0.5, scale))
    
    self.frame:SetScale(scale)
    configuration.scale = scale
    
    self:SaveConfiguration()
}

-- Set configuration option
function ResourceForecast:SetOption(option, value)
    if configuration[option] ~= nil then
        configuration[option] = value
        self:SaveConfiguration()
        
        -- Apply changes that need immediate updates
        if option == "showHistory" or option == "showAbilityIcons" then
            graphUpdateNeeded = true
        elseif option == "updateFrequency" then
            -- Nothing to change right now
        elseif option == "graphWidth" or option == "graphHeight" then
            -- Would need to rebuild UI - not implemented here
        elseif option == "alpha" then
            self.frame:SetAlpha(value)
        elseif option == "colorizeByClass" then
            -- Update border color
            if value then
                local classColor = RAID_CLASS_COLORS[playerClass]
                if classColor then
                    self.frame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1.0)
                end
            else
                self.frame:SetBackdropBorderColor(colors.border.r, colors.border.g, colors.border.b, colors.border.a)
            end
        end
    end
}

-- Handle slash command
function ResourceForecast:HandleCommand(msg)
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
            WR:Print("Resource Forecast scale set to " .. scale)
        else
            WR:Print("Current scale: " .. configuration.scale)
            WR:Print("Usage: /wr forecast scale <0.5-2.0>")
        end
    elseif command == "option" then
        local option, value = param:match("^(%S+)%s+(%S+)$")
        if option and value and configuration[option] ~= nil then
            local valueType = type(configuration[option])
            
            if valueType == "boolean" then
                self:SetOption(option, value == "on" or value == "true" or value == "1")
                WR:Print("Resource Forecast option " .. option .. " set to " .. (configuration[option] and "on" or "off"))
            elseif valueType == "number" then
                self:SetOption(option, tonumber(value) or configuration[option])
                WR:Print("Resource Forecast option " .. option .. " set to " .. configuration[option])
            else
                self:SetOption(option, value)
                WR:Print("Resource Forecast option " .. option .. " set to " .. value)
            end
        else
            WR:Print("Available options:")
            for option, value in pairs(configuration) do
                if type(value) == "boolean" then
                    WR:Print("  " .. option .. ": " .. (value and "on" or "off"))
                elseif type(value) == "number" then
                    WR:Print("  " .. option .. ": " .. value)
                else
                    WR:Print("  " .. option .. ": " .. tostring(value))
                end
            end
            WR:Print("Usage: /wr forecast option <name> <value>")
        end
    elseif command == "reset" then
        -- Reset position
        configuration.position = { x = 400, y = 0 }
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", configuration.position.x, configuration.position.y)
        WR:Print("Resource Forecast position reset")
        self:SaveConfiguration()
    else
        WR:Print("Resource Forecast Commands:")
        WR:Print("  /wr forecast - Toggle visibility")
        WR:Print("  /wr forecast scale <0.5-2.0> - Set scale")
        WR:Print("  /wr forecast option <name> <value> - Set option")
        WR:Print("  /wr forecast reset - Reset position")
    end
}

-- Register with the main addon
function ResourceForecast:RegisterWithAddon()
    -- Add slash command handler
    if WR.RegisterSlashCommand then
        WR.RegisterSlashCommand("forecast", function(msg) ResourceForecast:HandleCommand(msg) end)
    end
    
    -- Register with rotation enhancer if available
    if WR.RotationEnhancer and WR.RotationEnhancer.RegisterForecastProvider then
        WR.RotationEnhancer:RegisterForecastProvider(function()
            return ResourceForecast:GetForecastData()
        end)
    end
}

-- Get forecast data for other modules
function ResourceForecast:GetForecastData()
    return {
        predictions = resourceData.predictions,
        abilityPoints = resourceData.abilityPoints,
        current = resourceData.current,
        max = resourceData.max,
        regenRate = resourceData.regenRate,
        resourceType = primaryResourceType,
        resourceName = resourceName
    }
}

-- Initialize the module
ResourceForecast:Initialize()

return ResourceForecast