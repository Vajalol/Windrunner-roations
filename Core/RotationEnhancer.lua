local addonName, WR = ...

-- RotationEnhancer module for integrating all rotation enhancement modules
local RotationEnhancer = {}
WR.RotationEnhancer = RotationEnhancer

-- Local variables
local isInitialized = false
local registeredModules = {}
local currentRotationState = {}
local abilityScoreModifiers = {}
local buildAdjustments = {}
local gearAdjustments = {}
local playstyleAdjustments = {}
local encounterAdjustments = {}
local resourceAdjustments = {}

-- Initialize the RotationEnhancer
function RotationEnhancer:Initialize()
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            RotationEnhancer:ResetState()
        end
    end)
    
    -- Initialize state
    self:ResetState()
    
    -- Set initialization flag
    isInitialized = true
    
    WR:Debug("RotationEnhancer module initialized")
end

-- Reset rotation enhancer state
function RotationEnhancer:ResetState()
    currentRotationState = {
        class = select(2, UnitClass("player")),
        spec = GetSpecialization(),
        buildInfo = {},
        resourceInfo = {},
        gearInfo = {},
        encounterInfo = {},
        playstyleInfo = {}
    }
    
    abilityScoreModifiers = {}
    buildAdjustments = {}
    gearAdjustments = {}
    playstyleAdjustments = {}
    encounterAdjustments = {}
    resourceAdjustments = {}
    
    WR:Debug("RotationEnhancer state reset")
end

-- Register modules with the RotationEnhancer
function RotationEnhancer:RegisterClassKnowledge(module)
    registeredModules.ClassKnowledge = module
    WR:Debug("ClassKnowledge module registered with RotationEnhancer")
end

function RotationEnhancer:RegisterBuildAnalyzer(module)
    registeredModules.BuildAnalyzer = module
    WR:Debug("BuildAnalyzer module registered with RotationEnhancer")
end

function RotationEnhancer:RegisterResourceOptimizer(module)
    registeredModules.ResourceOptimizer = module
    WR:Debug("ResourceOptimizer module registered with RotationEnhancer")
end

function RotationEnhancer:RegisterLegendaryAndSetManager(module)
    registeredModules.LegendaryAndSetManager = module
    WR:Debug("LegendaryAndSetManager module registered with RotationEnhancer")
end

function RotationEnhancer:RegisterPlaystyleManager(module)
    registeredModules.PlaystyleManager = module
    WR:Debug("PlaystyleManager module registered with RotationEnhancer")
end

function RotationEnhancer:RegisterEncounterManager(module)
    registeredModules.EncounterManager = module
    WR:Debug("EncounterManager module registered with RotationEnhancer")
end

-- Update build information from BuildAnalyzer
function RotationEnhancer:UpdateBuildInfo(buildInfo)
    if not buildInfo then return end
    
    currentRotationState.buildInfo = buildInfo
    
    -- Apply build-specific adjustments to ability scores
    buildAdjustments = {}
    
    if buildInfo.matchedTemplate and buildInfo.matchedTemplate.priority_modifications then
        local mods = buildInfo.matchedTemplate.priority_modifications
        
        if mods.increase then
            for _, spellName in ipairs(mods.increase) do
                buildAdjustments[spellName] = 1.2 -- Increase by 20%
            end
        end
        
        if mods.decrease then
            for _, spellName in ipairs(mods.decrease) do
                buildAdjustments[spellName] = 0.8 -- Decrease by 20%
            end
        end
    end
    
    -- Update ability score modifiers
    self:UpdateAbilityScoreModifiers()
    
    WR:Debug("Updated build information in RotationEnhancer")
end

-- Update resource state from ResourceOptimizer
function RotationEnhancer:UpdateResourceState(resourceInfo)
    if not resourceInfo then return end
    
    currentRotationState.resourceInfo = resourceInfo
    
    -- Apply resource-specific adjustments to ability scores
    resourceAdjustments = {}
    
    -- Resource status and strategy-based adjustments
    local resourceStatus = resourceInfo.trend or "stable"
    local strategy = resourceInfo.strategy or "balanced"
    
    -- Update ability score modifiers
    self:UpdateAbilityScoreModifiers()
    
    WR:Debug("Updated resource state in RotationEnhancer")
end

-- Update gear effects from LegendaryAndSetManager
function RotationEnhancer:UpdateGearEffects(gearInfo)
    if not gearInfo then return end
    
    currentRotationState.gearInfo = gearInfo
    
    -- Apply gear-specific adjustments to ability scores
    gearAdjustments = {}
    
    if gearInfo.modifications then
        for _, mod in ipairs(gearInfo.modifications) do
            if mod.modifications then
                if mod.modifications.increase then
                    for _, spellName in ipairs(mod.modifications.increase) do
                        gearAdjustments[spellName] = (gearAdjustments[spellName] or 1) * 1.2 -- Increase by 20%
                    end
                end
                
                if mod.modifications.decrease then
                    for _, spellName in ipairs(mod.modifications.decrease) do
                        gearAdjustments[spellName] = (gearAdjustments[spellName] or 1) * 0.8 -- Decrease by 20%
                    end
                end
            end
        end
    end
    
    -- Update ability score modifiers
    self:UpdateAbilityScoreModifiers()
    
    WR:Debug("Updated gear effects in RotationEnhancer")
end

-- Handle playstyle changes from PlaystyleManager
function RotationEnhancer:PlaystyleChanged(profileName, profileSettings)
    if not profileSettings then return end
    
    currentRotationState.playstyleInfo = {
        profile = profileName,
        settings = profileSettings
    }
    
    -- Apply playstyle-specific adjustments to ability scores
    playstyleAdjustments = {}
    
    -- Complexity-based adjustments
    local complexity = profileSettings.rotation_complexity or 3 -- 1-5 scale
    
    -- Adjust based on complexity (simplified rotations prioritize core abilities)
    if complexity <= 2 then
        -- For low complexity, prioritize core abilities and deprioritize situational ones
        if registeredModules.ClassKnowledge then
            local classKnowledge = registeredModules.ClassKnowledge:GetPlayerClassKnowledge()
            if classKnowledge and classKnowledge.spells then
                for spellKey, spellData in pairs(classKnowledge.spells) do
                    if spellData.category == "core" then
                        playstyleAdjustments[spellKey] = 1.3 -- Boost core abilities
                    elseif spellData.category == "situational" then
                        playstyleAdjustments[spellKey] = 0.7 -- Reduce situational abilities
                    end
                end
            end
        end
    elseif complexity >= 4 then
        -- For high complexity, include more situational abilities
        if registeredModules.ClassKnowledge then
            local classKnowledge = registeredModules.ClassKnowledge:GetPlayerClassKnowledge()
            if classKnowledge and classKnowledge.spells then
                for spellKey, spellData in pairs(classKnowledge.spells) do
                    if spellData.category == "situational" then
                        playstyleAdjustments[spellKey] = 1.2 -- Boost situational abilities
                    elseif spellData.category == "advanced" then
                        playstyleAdjustments[spellKey] = 1.3 -- Boost advanced abilities
                    end
                end
            end
        end
    end
    
    -- Add more playstyle-specific adjustments based on other settings
    
    -- Update ability score modifiers
    self:UpdateAbilityScoreModifiers()
    
    WR:Debug("Updated playstyle in RotationEnhancer to: " .. profileName)
end

-- Apply encounter adjustments from EncounterManager
function RotationEnhancer:ApplyEncounterAdjustments(sourceKey, adjustments)
    if not adjustments then return end
    
    encounterAdjustments[sourceKey] = adjustments
    
    -- Update encounter info
    if registeredModules.EncounterManager then
        currentRotationState.encounterInfo = registeredModules.EncounterManager:GetEncounterStatus()
    end
    
    -- Update ability score modifiers for specific abilities
    if adjustments.priority_abilities then
        for spellID, factor in pairs(adjustments.priority_abilities) do
            -- Map spell ID to spell name if possible
            local spellName = GetSpellInfo(spellID)
            if spellName then
                encounterAdjustments[spellName] = factor
            end
        end
    end
    
    -- Update ability score modifiers
    self:UpdateAbilityScoreModifiers()
    
    WR:Debug("Applied encounter adjustments from source: " .. sourceKey)
end

-- Remove encounter adjustments from EncounterManager
function RotationEnhancer:RemoveEncounterAdjustments(sourceKey)
    if not encounterAdjustments[sourceKey] then return end
    
    -- Remove adjustments
    local adjustments = encounterAdjustments[sourceKey]
    encounterAdjustments[sourceKey] = nil
    
    -- Update encounter info
    if registeredModules.EncounterManager then
        currentRotationState.encounterInfo = registeredModules.EncounterManager:GetEncounterStatus()
    end
    
    -- Remove ability score modifiers for specific abilities
    if adjustments.priority_abilities then
        for spellID, _ in pairs(adjustments.priority_abilities) do
            -- Map spell ID to spell name if possible
            local spellName = GetSpellInfo(spellID)
            if spellName then
                encounterAdjustments[spellName] = nil
            end
        end
    end
    
    -- Update ability score modifiers
    self:UpdateAbilityScoreModifiers()
    
    WR:Debug("Removed encounter adjustments from source: " .. sourceKey)
end

-- Update ability score modifiers based on all factors
function RotationEnhancer:UpdateAbilityScoreModifiers()
    -- Clear existing modifiers
    abilityScoreModifiers = {}
    
    -- Add build adjustments
    for spellName, factor in pairs(buildAdjustments) do
        abilityScoreModifiers[spellName] = (abilityScoreModifiers[spellName] or 1) * factor
    end
    
    -- Add gear adjustments
    for spellName, factor in pairs(gearAdjustments) do
        abilityScoreModifiers[spellName] = (abilityScoreModifiers[spellName] or 1) * factor
    end
    
    -- Add playstyle adjustments
    for spellName, factor in pairs(playstyleAdjustments) do
        abilityScoreModifiers[spellName] = (abilityScoreModifiers[spellName] or 1) * factor
    end
    
    -- Add encounter adjustments
    for spellName, factor in pairs(encounterAdjustments) do
        if type(factor) == "number" then
            abilityScoreModifiers[spellName] = (abilityScoreModifiers[spellName] or 1) * factor
        end
    end
    
    -- Notify rotation system of updated modifiers if needed
    if WR.Rotation and WR.Rotation.UpdateAbilityScoreModifiers then
        WR.Rotation:UpdateAbilityScoreModifiers(abilityScoreModifiers)
    end
    
    WR:Debug("Updated ability score modifiers in RotationEnhancer")
end

-- Get the modified score for an ability
function RotationEnhancer:GetModifiedAbilityScore(abilityName, baseScore)
    if not abilityName or not baseScore then
        return baseScore
    end
    
    local modifier = abilityScoreModifiers[abilityName] or 1
    
    -- Apply resource-specific adjustments if available
    if registeredModules.ResourceOptimizer and currentRotationState.resourceInfo then
        local resourceState = currentRotationState.resourceInfo
        
        -- Check if ability is a resource generator or spender
        -- This would be more sophisticated in a real implementation
        
        -- For demonstration, we'll apply some simple resource-based adjustments
        if resourceState.primary and resourceState.primary.percent < 0.3 then
            -- Low on primary resource - boost generators
            if self:IsResourceGenerator(abilityName) then
                modifier = modifier * 1.3
            elseif self:IsResourceSpender(abilityName) then
                modifier = modifier * 0.7
            end
        elseif resourceState.primary and resourceState.primary.percent > 0.8 then
            -- High on primary resource - boost spenders
            if self:IsResourceSpender(abilityName) then
                modifier = modifier * 1.3
            elseif self:IsResourceGenerator(abilityName) then
                modifier = modifier * 0.9
            end
        end
    end
    
    -- Apply encounter-specific adjustments
    if currentRotationState.encounterInfo and currentRotationState.encounterInfo.active then
        -- Special handling for movement/defensive mechanics
        local mechanic = currentRotationState.encounterInfo.mechanic
        
        if mechanic then
            local mechanicAdjustment = encounterAdjustments["mechanic_" .. mechanic]
            if mechanicAdjustment then
                if mechanicAdjustment.movement_priority and self:IsMovementAbility(abilityName) then
                    modifier = modifier * 2.0 -- Heavily prioritize movement abilities
                end
                
                if mechanicAdjustment.defensive_priority and self:IsDefensiveAbility(abilityName) then
                    modifier = modifier * 2.0 -- Heavily prioritize defensive abilities
                end
            end
        end
    }
    
    return baseScore * modifier
end

-- Check if an ability is a resource generator
function RotationEnhancer:IsResourceGenerator(abilityName)
    -- In a real implementation, this would check the ClassKnowledge module
    -- For demonstration, we'll use a placeholder implementation
    
    if registeredModules.ClassKnowledge then
        local spell = registeredModules.ClassKnowledge:GetSpellByName(abilityName)
        return spell and spell.category == "generator"
    end
    
    return false
end

-- Check if an ability is a resource spender
function RotationEnhancer:IsResourceSpender(abilityName)
    -- In a real implementation, this would check the ClassKnowledge module
    -- For demonstration, we'll use a placeholder implementation
    
    if registeredModules.ClassKnowledge then
        local spell = registeredModules.ClassKnowledge:GetSpellByName(abilityName)
        return spell and spell.category == "spender"
    end
    
    return false
end

-- Check if an ability is a movement ability
function RotationEnhancer:IsMovementAbility(abilityName)
    -- In a real implementation, this would check the ClassKnowledge module
    -- For demonstration, we'll use a placeholder implementation
    
    if registeredModules.ClassKnowledge then
        local spell = registeredModules.ClassKnowledge:GetSpellByName(abilityName)
        return spell and spell.category == "movement"
    end
    
    return false
end

-- Check if an ability is a defensive ability
function RotationEnhancer:IsDefensiveAbility(abilityName)
    -- In a real implementation, this would check the ClassKnowledge module
    -- For demonstration, we'll use a placeholder implementation
    
    if registeredModules.ClassKnowledge then
        local spell = registeredModules.ClassKnowledge:GetSpellByName(abilityName)
        return spell and spell.category == "defensive"
    end
    
    return false
end

-- Get current rotation state
function RotationEnhancer:GetRotationState()
    return currentRotationState
end

-- Get ability score modifiers
function RotationEnhancer:GetAbilityScoreModifiers()
    return abilityScoreModifiers
end

-- GetEvaluatedAbilities - get a list of abilities with their final scores
function RotationEnhancer:GetEvaluatedAbilities(abilities)
    if not abilities then return {} end
    
    local evaluatedAbilities = {}
    
    for i, ability in ipairs(abilities) do
        local evaluatedAbility = {
            name = ability.name,
            id = ability.id,
            baseScore = ability.score,
            finalScore = self:GetModifiedAbilityScore(ability.name, ability.score),
            modifiers = {}
        }
        
        -- Add individual modifiers for UI/debugging
        if buildAdjustments[ability.name] then
            evaluatedAbility.modifiers.build = buildAdjustments[ability.name]
        end
        
        if gearAdjustments[ability.name] then
            evaluatedAbility.modifiers.gear = gearAdjustments[ability.name]
        end
        
        if playstyleAdjustments[ability.name] then
            evaluatedAbility.modifiers.playstyle = playstyleAdjustments[ability.name]
        end
        
        if encounterAdjustments[ability.name] then
            evaluatedAbility.modifiers.encounter = encounterAdjustments[ability.name]
        end
        
        -- Resource-based modifiers would be calculated dynamically
        
        table.insert(evaluatedAbilities, evaluatedAbility)
    end
    
    -- Sort by final score, descending
    table.sort(evaluatedAbilities, function(a, b) return a.finalScore > b.finalScore end)
    
    return evaluatedAbilities
end

-- Create Enhanced UI Panel
function RotationEnhancer:CreateEnhancedUI(parent)
    if not parent then return end
    
    -- Create the main frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsEnhancedUI", parent, "BackdropTemplate")
    frame:SetSize(800, 600)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Windrunner Rotations Enhanced System")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab system
    local tabs = {}
    local tabContents = {}
    local tabWidth = 130
    local tabHeight = 30
    local tabNames = {"Overview", "Abilities", "Build", "Gear", "Playstyle", "Encounter"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -40)
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetText(tabName)
        
        -- Create highlight texture
        local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create selected texture
        local selectedTexture = tab:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        tab.selectedTexture = selectedTexture
        
        -- Create tab content frame
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 80)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
        content:Hide()
        
        -- Set up tab behavior
        tab:SetScript("OnClick", function()
            -- Hide all contents
            for _, contentFrame in ipairs(tabContents) do
                contentFrame:Hide()
            end
            
            -- Show this content
            content:Show()
            
            -- Update tab appearance
            for _, tabButton in ipairs(tabs) do
                tabButton.selectedTexture:Hide()
            end
            
            tab.selectedTexture:Show()
            
            -- Update content
            if tabName == "Overview" then
                RotationEnhancer:UpdateOverviewTab(content)
            elseif tabName == "Abilities" then
                RotationEnhancer:UpdateAbilitiesTab(content)
            elseif tabName == "Build" then
                RotationEnhancer:UpdateBuildTab(content)
            elseif tabName == "Gear" then
                RotationEnhancer:UpdateGearTab(content)
            elseif tabName == "Playstyle" then
                RotationEnhancer:UpdatePlaystyleTab(content)
            elseif tabName == "Encounter" then
                RotationEnhancer:UpdateEncounterTab(content)
            end
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Update overview tab content
    function RotationEnhancer:UpdateOverviewTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add refresh button
        local refreshButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        refreshButton:SetSize(100, 24)
        refreshButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            RotationEnhancer:UpdateOverviewTab(content)
        end)
        
        -- Get rotation state
        local rotationState = self:GetRotationState()
        
        -- Title
        local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        title:SetText("Enhanced Rotation System Overview")
        
        local y = -30
        
        -- Character info section
        local infoFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        infoFrame:SetSize(scrollChild:GetWidth() - 20, 100)
        infoFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        infoFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        infoFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Character info title
        local infoTitle = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        infoTitle:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 15, -15)
        infoTitle:SetText("Character Information")
        
        -- Character class and spec
        local className = select(2, UnitClass("player"))
        local specID = GetSpecialization()
        local specName = specID and select(2, GetSpecializationInfo(specID)) or "Unknown"
        
        local classText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        classText:SetPoint("TOPLEFT", infoTitle, "BOTTOMLEFT", 10, -10)
        classText:SetText("Class: " .. className)
        
        local specText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        specText:SetPoint("TOPLEFT", classText, "BOTTOMLEFT", 0, -5)
        specText:SetText("Specialization: " .. specName)
        
        -- Registered modules
        local modulesText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        modulesText:SetPoint("TOPLEFT", specText, "BOTTOMLEFT", 0, -5)
        
        local activeModules = {}
        for name, module in pairs(registeredModules) do
            table.insert(activeModules, name)
        end
        
        modulesText:SetText("Active Modules: " .. table.concat(activeModules, ", "))
        
        y = y - infoFrame:GetHeight() - 10
        
        -- System status section
        local systemFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        systemFrame:SetSize(scrollChild:GetWidth() - 20, 200)
        systemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        systemFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        systemFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- System status title
        local systemTitle = systemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        systemTitle:SetPoint("TOPLEFT", systemFrame, "TOPLEFT", 15, -15)
        systemTitle:SetText("System Status")
        
        local statusY = -40
        
        -- Build status
        local buildText = systemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        buildText:SetPoint("TOPLEFT", systemFrame, "TOPLEFT", 20, statusY)
        
        if rotationState.buildInfo and rotationState.buildInfo.buildSummary then
            buildText:SetText("Build: " .. rotationState.buildInfo.buildSummary)
        else
            buildText:SetText("Build: No build detected")
        end
        
        statusY = statusY - 20
        
        -- Gear status
        local gearText = systemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        gearText:SetPoint("TOPLEFT", systemFrame, "TOPLEFT", 20, statusY)
        
        local legendaryCount = rotationState.gearInfo and rotationState.gearInfo.legendaries and #rotationState.gearInfo.legendaries or 0
        local tierSetCount = 0
        if rotationState.gearInfo and rotationState.gearInfo.tierSets then
            for _, count in pairs(rotationState.gearInfo.tierSets) do
                tierSetCount = tierSetCount + 1
            end
        end
        
        gearText:SetText("Gear: " .. legendaryCount .. " legendary items, " .. tierSetCount .. " tier sets")
        
        statusY = statusY - 20
        
        -- Playstyle status
        local playstyleText = systemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        playstyleText:SetPoint("TOPLEFT", systemFrame, "TOPLEFT", 20, statusY)
        
        if rotationState.playstyleInfo and rotationState.playstyleInfo.profile then
            playstyleText:SetText("Playstyle: " .. rotationState.playstyleInfo.profile)
        else
            playstyleText:SetText("Playstyle: Default")
        end
        
        statusY = statusY - 20
        
        -- Encounter status
        local encounterText = systemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        encounterText:SetPoint("TOPLEFT", systemFrame, "TOPLEFT", 20, statusY)
        
        if rotationState.encounterInfo and rotationState.encounterInfo.active then
            encounterText:SetText("Encounter: " .. (rotationState.encounterInfo.name or "Unknown") .. 
                               " (Phase " .. rotationState.encounterInfo.phase .. ")")
        else
            encounterText:SetText("Encounter: None")
        end
        
        statusY = statusY - 20
        
        -- Resource status
        local resourceText = systemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        resourceText:SetPoint("TOPLEFT", systemFrame, "TOPLEFT", 20, statusY)
        
        if rotationState.resourceInfo and rotationState.resourceInfo.strategy then
            resourceText:SetText("Resource Strategy: " .. rotationState.resourceInfo.strategy)
        else
            resourceText:SetText("Resource Strategy: Default")
        end
        
        -- Rotation adjustments section
        y = y - systemFrame:GetHeight() - 10
        
        local adjustmentsFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        adjustmentsFrame:SetSize(scrollChild:GetWidth() - 20, 150)
        adjustmentsFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        adjustmentsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        adjustmentsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Adjustments title
        local adjustmentsTitle = adjustmentsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        adjustmentsTitle:SetPoint("TOPLEFT", adjustmentsFrame, "TOPLEFT", 15, -15)
        adjustmentsTitle:SetText("Rotation Adjustments")
        
        local adjustY = -40
        
        -- Count adjustments by source
        local adjustmentCounts = {
            build = 0,
            gear = 0,
            playstyle = 0,
            encounter = 0
        }
        
        for spellName, _ in pairs(buildAdjustments) do
            adjustmentCounts.build = adjustmentCounts.build + 1
        end
        
        for spellName, _ in pairs(gearAdjustments) do
            adjustmentCounts.gear = adjustmentCounts.gear + 1
        end
        
        for spellName, _ in pairs(playstyleAdjustments) do
            adjustmentCounts.playstyle = adjustmentCounts.playstyle + 1
        end
        
        for spellName, value in pairs(encounterAdjustments) do
            if type(value) == "number" then
                adjustmentCounts.encounter = adjustmentCounts.encounter + 1
            end
        end
        
        -- Display adjustment counts
        local buildAdjText = adjustmentsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        buildAdjText:SetPoint("TOPLEFT", adjustmentsFrame, "TOPLEFT", 20, adjustY)
        buildAdjText:SetText("Build Adjustments: " .. adjustmentCounts.build .. " abilities modified")
        
        adjustY = adjustY - 20
        
        local gearAdjText = adjustmentsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        gearAdjText:SetPoint("TOPLEFT", adjustmentsFrame, "TOPLEFT", 20, adjustY)
        gearAdjText:SetText("Gear Adjustments: " .. adjustmentCounts.gear .. " abilities modified")
        
        adjustY = adjustY - 20
        
        local playstyleAdjText = adjustmentsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        playstyleAdjText:SetPoint("TOPLEFT", adjustmentsFrame, "TOPLEFT", 20, adjustY)
        playstyleAdjText:SetText("Playstyle Adjustments: " .. adjustmentCounts.playstyle .. " abilities modified")
        
        adjustY = adjustY - 20
        
        local encounterAdjText = adjustmentsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        encounterAdjText:SetPoint("TOPLEFT", adjustmentsFrame, "TOPLEFT", 20, adjustY)
        encounterAdjText:SetText("Encounter Adjustments: " .. adjustmentCounts.encounter .. " abilities modified")
        
        -- Set scroll child height
        y = y - adjustmentsFrame:GetHeight() - 20
        scrollChild:SetHeight(math.abs(y))
    end
    
    -- Update abilities tab content
    function RotationEnhancer:UpdateAbilitiesTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add refresh button
        local refreshButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        refreshButton:SetSize(100, 24)
        refreshButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            RotationEnhancer:UpdateAbilitiesTab(content)
        end)
        
        -- Title
        local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        title:SetText("Ability Adjustments")
        
        local y = -30
        
        -- Get spell data from ClassKnowledge if available
        local spellData = {}
        
        if registeredModules.ClassKnowledge then
            local classKnowledge = registeredModules.ClassKnowledge:GetPlayerClassKnowledge()
            if classKnowledge and classKnowledge.spells then
                spellData = classKnowledge.spells
            end
        end
        
        -- Header row
        local headerFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        headerFrame:SetSize(scrollChild:GetWidth() - 20, 30)
        headerFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        headerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        
        -- Header columns
        local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 10, -8)
        nameHeader:SetText("Ability Name")
        nameHeader:SetWidth(150)
        
        local categoryHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        categoryHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 160, -8)
        categoryHeader:SetText("Category")
        categoryHeader:SetWidth(100)
        
        local buildHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        buildHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 260, -8)
        buildHeader:SetText("Build")
        buildHeader:SetWidth(60)
        
        local gearHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        gearHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 320, -8)
        gearHeader:SetText("Gear")
        gearHeader:SetWidth(60)
        
        local playstyleHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        playstyleHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 380, -8)
        playstyleHeader:SetText("Playstyle")
        playstyleHeader:SetWidth(60)
        
        local encounterHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        encounterHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 440, -8)
        encounterHeader:SetText("Encounter")
        encounterHeader:SetWidth(60)
        
        local totalHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        totalHeader:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 500, -8)
        totalHeader:SetText("Total")
        totalHeader:SetWidth(60)
        
        y = y - headerFrame:GetHeight() - 2
        
        -- Create ability list
        local rowHeight = 25
        local rowBgColors = {
            {r = 0.1, g = 0.1, b = 0.1, a = 0.5},
            {r = 0.15, g = 0.15, b = 0.15, a = 0.5}
        }
        
        local colorIndex = 1
        
        -- Combine all abilities that have adjustments
        local modifiedAbilities = {}
        
        -- Add all abilities from score modifiers
        for abilityName, _ in pairs(abilityScoreModifiers) do
            modifiedAbilities[abilityName] = true
        end
        
        -- Add all abilities from spell data if available
        if spellData then
            for abilityKey, _ in pairs(spellData) do
                modifiedAbilities[abilityKey] = true
            end
        end
        
        -- Convert to sorted array
        local abilityList = {}
        for abilityName, _ in pairs(modifiedAbilities) do
            table.insert(abilityList, abilityName)
        end
        
        table.sort(abilityList)
        
        for _, abilityName in ipairs(abilityList) do
            local spell = spellData[abilityName]
            local spellId = spell and spell.id or 0
            local spellCategory = spell and spell.category or "unknown"
            
            -- Get modifiers
            local buildMod = buildAdjustments[abilityName] or 1
            local gearMod = gearAdjustments[abilityName] or 1
            local playstyleMod = playstyleAdjustments[abilityName] or 1
            local encounterMod = encounterAdjustments[abilityName] or 1
            local totalMod = abilityScoreModifiers[abilityName] or 1
            
            -- Create row
            local rowFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            rowFrame:SetSize(scrollChild:GetWidth() - 20, rowHeight)
            rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            rowFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })
            
            local bgColor = rowBgColors[colorIndex]
            rowFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
            
            -- Alternate row colors
            colorIndex = colorIndex == 1 and 2 or 1
            
            -- Spell icon (if available)
            if spellId and spellId > 0 then
                local icon = rowFrame:CreateTexture(nil, "ARTWORK")
                icon:SetSize(rowHeight - 4, rowHeight - 4)
                icon:SetPoint("LEFT", rowFrame, "LEFT", 2, 0)
                icon:SetTexture(select(3, GetSpellInfo(spellId)) or "Interface\\Icons\\INV_Misc_QuestionMark")
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim the icon border
            end
            
            -- Spell name
            local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameText:SetPoint("LEFT", rowFrame, "LEFT", 30, 0)
            nameText:SetWidth(130)
            nameText:SetJustifyH("LEFT")
            
            -- Use proper spell name if available
            if spellId and spellId > 0 then
                nameText:SetText(GetSpellInfo(spellId) or abilityName)
            else
                nameText:SetText(abilityName)
            end
            
            -- Category
            local categoryText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            categoryText:SetPoint("LEFT", rowFrame, "LEFT", 160, 0)
            categoryText:SetWidth(100)
            categoryText:SetJustifyH("LEFT")
            categoryText:SetText(spellCategory)
            
            -- Build modifier
            local buildText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            buildText:SetPoint("LEFT", rowFrame, "LEFT", 260, 0)
            buildText:SetWidth(60)
            buildText:SetJustifyH("CENTER")
            buildText:SetText(string.format("%.2f", buildMod))
            
            -- Color code modifiers
            if buildMod > 1 then
                buildText:SetTextColor(0, 1, 0)
            elseif buildMod < 1 then
                buildText:SetTextColor(1, 0.5, 0)
            end
            
            -- Gear modifier
            local gearText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            gearText:SetPoint("LEFT", rowFrame, "LEFT", 320, 0)
            gearText:SetWidth(60)
            gearText:SetJustifyH("CENTER")
            gearText:SetText(string.format("%.2f", gearMod))
            
            if gearMod > 1 then
                gearText:SetTextColor(0, 1, 0)
            elseif gearMod < 1 then
                gearText:SetTextColor(1, 0.5, 0)
            end
            
            -- Playstyle modifier
            local playstyleText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            playstyleText:SetPoint("LEFT", rowFrame, "LEFT", 380, 0)
            playstyleText:SetWidth(60)
            playstyleText:SetJustifyH("CENTER")
            playstyleText:SetText(string.format("%.2f", playstyleMod))
            
            if playstyleMod > 1 then
                playstyleText:SetTextColor(0, 1, 0)
            elseif playstyleMod < 1 then
                playstyleText:SetTextColor(1, 0.5, 0)
            end
            
            -- Encounter modifier
            local encounterText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            encounterText:SetPoint("LEFT", rowFrame, "LEFT", 440, 0)
            encounterText:SetWidth(60)
            encounterText:SetJustifyH("CENTER")
            encounterText:SetText(string.format("%.2f", encounterMod))
            
            if encounterMod > 1 then
                encounterText:SetTextColor(0, 1, 0)
            elseif encounterMod < 1 then
                encounterText:SetTextColor(1, 0.5, 0)
            end
            
            -- Total modifier
            local totalText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            totalText:SetPoint("LEFT", rowFrame, "LEFT", 500, 0)
            totalText:SetWidth(60)
            totalText:SetJustifyH("CENTER")
            totalText:SetText(string.format("%.2f", totalMod))
            
            if totalMod > 1 then
                totalText:SetTextColor(0, 1, 0)
            elseif totalMod < 1 then
                totalText:SetTextColor(1, 0.5, 0)
            end
            
            y = y - rowHeight - 2
        }
        
        -- Set scroll child height
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Update build tab content
    function RotationEnhancer:UpdateBuildTab(content)
        -- If BuildAnalyzer is registered, use its UI
        if registeredModules.BuildAnalyzer and registeredModules.BuildAnalyzer.CreateBuildAnalyzerUI then
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create build analyzer UI
            local buildUI = registeredModules.BuildAnalyzer:CreateBuildAnalyzerUI(content)
            buildUI:SetParent(content)
            buildUI:ClearAllPoints()
            buildUI:SetAllPoints()
            buildUI:Show()
        else
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create a message indicating the module is not available
            local message = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            message:SetPoint("CENTER", content, "CENTER", 0, 0)
            message:SetText("Build Analyzer module is not available")
        end
    end
    
    -- Update gear tab content
    function RotationEnhancer:UpdateGearTab(content)
        -- If LegendaryAndSetManager is registered, use its UI
        if registeredModules.LegendaryAndSetManager and registeredModules.LegendaryAndSetManager.CreateEffectsUI then
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create gear effects UI
            local gearUI = registeredModules.LegendaryAndSetManager:CreateEffectsUI(content)
            gearUI:SetParent(content)
            gearUI:ClearAllPoints()
            gearUI:SetAllPoints()
            gearUI:Show()
        else
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create a message indicating the module is not available
            local message = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            message:SetPoint("CENTER", content, "CENTER", 0, 0)
            message:SetText("Legendary and Set Manager module is not available")
        end
    end
    
    -- Update playstyle tab content
    function RotationEnhancer:UpdatePlaystyleTab(content)
        -- If PlaystyleManager is registered, use its UI
        if registeredModules.PlaystyleManager and registeredModules.PlaystyleManager.CreatePlaystyleUI then
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create playstyle UI
            local playstyleUI = registeredModules.PlaystyleManager:CreatePlaystyleUI(content)
            playstyleUI:SetParent(content)
            playstyleUI:ClearAllPoints()
            playstyleUI:SetAllPoints()
            playstyleUI:Show()
        else
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create a message indicating the module is not available
            local message = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            message:SetPoint("CENTER", content, "CENTER", 0, 0)
            message:SetText("Playstyle Manager module is not available")
        end
    end
    
    -- Update encounter tab content
    function RotationEnhancer:UpdateEncounterTab(content)
        -- If EncounterManager is registered, use its UI
        if registeredModules.EncounterManager and registeredModules.EncounterManager.CreateEncounterUI then
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create encounter UI
            local encounterUI = registeredModules.EncounterManager:CreateEncounterUI(content)
            encounterUI:SetParent(content)
            encounterUI:ClearAllPoints()
            encounterUI:SetAllPoints()
            encounterUI:Show()
        else
            -- Clear existing content
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                child:Hide()
                child:SetParent(nil)
            end
            
            -- Create a message indicating the module is not available
            local message = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            message:SetPoint("CENTER", content, "CENTER", 0, 0)
            message:SetText("Encounter Manager module is not available")
        end
    end
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Update first tab content
    RotationEnhancer:UpdateOverviewTab(tabContents[1])
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Initialize the module
RotationEnhancer:Initialize()

return RotationEnhancer