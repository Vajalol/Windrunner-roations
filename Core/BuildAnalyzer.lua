local addonName, WR = ...

-- BuildAnalyzer module for detecting and analyzing player builds
local BuildAnalyzer = {}
WR.BuildAnalyzer = BuildAnalyzer

-- Local variables to store build information
local currentBuild = {
    class = nil,
    specID = nil,
    specName = nil,
    talentString = nil,
    talentTiers = {},
    talentChoices = {},
    strongPoints = {},
    weakPoints = {},
    suggestedChanges = {},
    matchedTemplate = nil,
    matchScore = 0,
    buildSummary = "",
    lastUpdateTime = 0
}

-- Constants
local UPDATE_INTERVAL = 1 -- How often to check for talent changes (seconds)
local TALENT_SCAN_DEPTH = 7 -- How many talent tiers to scan
local SIMILARITY_THRESHOLD = 0.7 -- Threshold for considering a build template a match (0.0-1.0)

-- Templates for common builds
local buildTemplates = {
    -- These will be populated from ClassKnowledge
}

-- Configuration
local config = {
    enableBuildScanning = true,
    enableBuildAnalysis = true,
    enableBuildSuggestions = true,
    enableAutomaticAdjustments = true,
    buildChangeNotifications = true,
    analysisDetailLevel = 2, -- 1-3, higher is more detailed
    scanFrequency = 2, -- Seconds between scans
    minimumSimilarityThreshold = 0.5 -- Minimum similarity to consider a template
}

-- Initialize the BuildAnalyzer
function BuildAnalyzer:Initialize()
    -- Load saved settings
    if WindrunnerRotationsDB and WindrunnerRotationsDB.BuildAnalyzer then
        local savedConfig = WindrunnerRotationsDB.BuildAnalyzer
        for k, v in pairs(savedConfig) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
    end
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Initial build scan after a short delay
            C_Timer.After(2, function()
                BuildAnalyzer:ScanCurrentBuild()
            end)
            
            -- Set up periodic scanning if enabled
            if config.enableBuildScanning then
                C_Timer.NewTicker(config.scanFrequency, function()
                    BuildAnalyzer:ScanCurrentBuild()
                end)
            end
        elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
            -- Talents or spec changed, scan build
            BuildAnalyzer:ScanCurrentBuild()
        elseif event == "PLAYER_LOGOUT" then
            BuildAnalyzer:SaveSettings()
        end
    end)
    
    -- Import build templates from ClassKnowledge
    self:ImportBuildTemplates()
    
    -- Register with rotation enhancer
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RegisterBuildAnalyzer(self)
    end
    
    WR:Debug("BuildAnalyzer module initialized")
end

-- Save settings
function BuildAnalyzer:SaveSettings()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.BuildAnalyzer = CopyTable(config)
}

-- Import build templates from ClassKnowledge
function BuildAnalyzer:ImportBuildTemplates()
    if not WR.ClassKnowledge or not WR.ClassKnowledge.knowledgeDB then
        WR:Debug("Unable to import build templates - ClassKnowledge not available")
        return
    end
    
    buildTemplates = {}
    
    -- Loop through all classes and specs
    for className, classData in pairs(WR.ClassKnowledge.knowledgeDB) do
        buildTemplates[className] = {}
        
        for specID, specData in pairs(classData) do
            buildTemplates[className][specID] = {}
            
            -- Get talent builds if available
            if specData.talent_builds then
                for buildName, buildData in pairs(specData.talent_builds) do
                    table.insert(buildTemplates[className][specID], {
                        name = buildName,
                        talents = buildData.talents,
                        description = buildData.description,
                        priority_modifications = buildData.priority_modifications
                    })
                end
            end
        end
    end
    
    WR:Debug("Imported build templates from ClassKnowledge")
end

-- Scan the current player build
function BuildAnalyzer:ScanCurrentBuild()
    -- Don't scan too frequently
    local currentTime = GetTime()
    if currentTime - currentBuild.lastUpdateTime < UPDATE_INTERVAL then
        return
    end
    
    -- Update timestamp
    currentBuild.lastUpdateTime = currentTime
    
    -- Get class and spec information
    local _, className = UnitClass("player")
    currentBuild.class = className
    
    local currentSpec = GetSpecialization()
    if not currentSpec then
        return -- No spec selected yet
    end
    
    local currentSpecID, currentSpecName = GetSpecializationInfo(currentSpec)
    currentBuild.specID = currentSpecID
    currentBuild.specName = currentSpecName
    
    -- Scan talents
    self:ScanTalents()
    
    -- Compare to templates
    self:MatchBuildTemplate()
    
    -- Analyze build
    if config.enableBuildAnalysis then
        self:AnalyzeBuild()
    end
    
    -- Check if build changed significantly
    if self:HasBuildChangedSignificantly() and config.buildChangeNotifications then
        self:NotifyBuildChanged()
    end
    
    -- Apply automatic adjustments if enabled
    if config.enableAutomaticAdjustments and currentBuild.matchedTemplate then
        self:ApplyBuildAdjustments()
    end
    
    WR:Debug("Build scan complete for " .. className .. " " .. currentSpecName)
end

-- Scan player talents
function BuildAnalyzer:ScanTalents()
    currentBuild.talentTiers = {}
    currentBuild.talentChoices = {}
    
    -- This is a simplified version - in a real implementation, this would
    -- scan the actual talent tree UI elements or use the C_Talent API
    
    -- Generate a talent string
    -- For demonstration, we'll create a simplified talent string format
    local talentString = ""
    
    for tier = 1, TALENT_SCAN_DEPTH do
        local choice = C_Talents and C_Talents.GetActiveTalentSelection and 
                      C_Talents.GetActiveTalentSelection(tier) or math.random(1, 3)
        
        talentString = talentString .. choice
        
        -- Store tier and choice
        currentBuild.talentTiers[tier] = {
            tier = tier,
            choice = choice
        }
        
        currentBuild.talentChoices[tier] = choice
    end
    
    -- Add some padding to match template format
    talentString = talentString .. "aaaa123aaaa12aaaa"
    
    -- Store talent string
    currentBuild.talentString = talentString
    
    WR:Debug("Scanned talents: " .. talentString)
end

-- Match current build to known templates
function BuildAnalyzer:MatchBuildTemplate()
    local className = currentBuild.class
    local specID = currentBuild.specID
    
    if not buildTemplates[className] or not buildTemplates[className][specID] or 
       #buildTemplates[className][specID] == 0 then
        currentBuild.matchedTemplate = nil
        currentBuild.matchScore = 0
        return
    end
    
    local bestMatch = nil
    local bestScore = 0
    
    for _, template in ipairs(buildTemplates[className][specID]) do
        local similarity = self:CalculateTalentSimilarity(currentBuild.talentString, template.talents)
        
        if similarity > bestScore then
            bestScore = similarity
            bestMatch = template
        end
    end
    
    -- Only consider it a match if similarity is above threshold
    if bestScore >= config.minimumSimilarityThreshold then
        currentBuild.matchedTemplate = bestMatch
        currentBuild.matchScore = bestScore
        
        WR:Debug("Matched build template: " .. bestMatch.name .. " (score: " .. string.format("%.2f", bestScore) .. ")")
    else
        currentBuild.matchedTemplate = nil
        currentBuild.matchScore = 0
        
        WR:Debug("No matching build template found")
    end
end

-- Calculate similarity between two talent strings
function BuildAnalyzer:CalculateTalentSimilarity(talents1, talents2)
    local score = 0
    local maxScore = math.min(#talents1, #talents2)
    
    for i = 1, maxScore do
        if talents1:sub(i,i) == talents2:sub(i,i) then
            score = score + 1
        end
    end
    
    return score / maxScore
end

-- Analyze the current build
function BuildAnalyzer:AnalyzeBuild()
    -- Reset analysis data
    currentBuild.strongPoints = {}
    currentBuild.weakPoints = {}
    currentBuild.suggestedChanges = {}
    
    -- If we have a matched template with high similarity, not much to suggest
    if currentBuild.matchedTemplate and currentBuild.matchScore > SIMILARITY_THRESHOLD then
        table.insert(currentBuild.strongPoints, "Build closely matches the \"" .. currentBuild.matchedTemplate.name .. "\" template")
        
        -- Create build summary
        currentBuild.buildSummary = currentBuild.matchedTemplate.description
        
        return
    end
    
    -- If we have a partial match, suggest improvements to align with the template
    if currentBuild.matchedTemplate and currentBuild.matchScore >= config.minimumSimilarityThreshold then
        table.insert(currentBuild.strongPoints, "Build partially matches the \"" .. currentBuild.matchedTemplate.name .. "\" template")
        table.insert(currentBuild.weakPoints, "Some talent choices differ from the optimal template")
        
        -- Compare talents and suggest changes
        local templateTalents = currentBuild.matchedTemplate.talents
        local playerTalents = currentBuild.talentString
        
        for i = 1, math.min(TALENT_SCAN_DEPTH, #templateTalents, #playerTalents) do
            if playerTalents:sub(i,i) ~= templateTalents:sub(i,i) then
                table.insert(currentBuild.suggestedChanges, {
                    tier = i,
                    currentChoice = tonumber(playerTalents:sub(i,i)),
                    suggestedChoice = tonumber(templateTalents:sub(i,i)),
                    reason = "Aligns with the " .. currentBuild.matchedTemplate.name .. " build"
                })
            end
        end
        
        -- Create build summary
        currentBuild.buildSummary = "Partial " .. currentBuild.matchedTemplate.name .. " build with " 
                                 .. #currentBuild.suggestedChanges .. " suboptimal talent choices"
    else
        -- No good template match, provide generic analysis
        table.insert(currentBuild.weakPoints, "Build does not match any known optimal templates")
        table.insert(currentBuild.suggestedChanges, {
            tier = 0, -- Special value to indicate general suggestion
            reason = "Consider using one of the recommended builds for your spec"
        })
        
        -- Create build summary
        currentBuild.buildSummary = "Custom " .. currentBuild.specName .. " build (non-standard)"
    end
    
    -- Class-specific analysis
    self:PerformClassSpecificAnalysis()
}

-- Perform class-specific build analysis
function BuildAnalyzer:PerformClassSpecificAnalysis()
    local className = currentBuild.class
    local specID = currentBuild.specID
    
    -- Check if we have class-specific analysis for this class/spec
    local analysisFunction = self["Analyze_" .. className .. "_" .. specID]
    
    if type(analysisFunction) == "function" then
        analysisFunction(self)
    else
        -- Generic analysis fallback
        self:PerformGenericAnalysis()
    end
end

-- Generic analysis for any class/spec
function BuildAnalyzer:PerformGenericAnalysis()
    -- Check for obvious talent synergies
    for tier1 = 1, TALENT_SCAN_DEPTH do
        for tier2 = 1, TALENT_SCAN_DEPTH do
            if tier1 ~= tier2 then
                local choice1 = currentBuild.talentChoices[tier1]
                local choice2 = currentBuild.talentChoices[tier2]
                
                -- This is where you would check for specific talent combinations
                -- In a real implementation, this would use actual talent IDs and known synergies
                
                -- For demonstration, we'll use a placeholder logic
                if choice1 == 1 and choice2 == 3 and tier1 == 2 and tier2 == 4 then
                    table.insert(currentBuild.strongPoints, 
                        "Good synergy between tier " .. tier1 .. " and tier " .. tier2 .. " talents")
                elseif choice1 == 2 and choice2 == 2 and tier1 == 1 and tier2 == 3 then
                    table.insert(currentBuild.weakPoints, 
                        "Potential anti-synergy between tier " .. tier1 .. " and tier " .. tier2 .. " talents")
                end
            end
        end
    end
    
    -- Add generic strength for completeness
    if #currentBuild.strongPoints == 0 then
        table.insert(currentBuild.strongPoints, "Build has a balanced selection of talents")
    end
}

-- Check if build has changed significantly
function BuildAnalyzer:HasBuildChangedSignificantly()
    -- In a real implementation, this would compare current build to previously stored build
    -- For demonstration, we'll return false to avoid spam
    return false
end

-- Notify about build change
function BuildAnalyzer:NotifyBuildChanged()
    local message = "Your build has changed to: " .. currentBuild.buildSummary
    
    -- Display notification
    if WR.UI and WR.UI.ShowNotification then
        WR.UI:ShowNotification(message, "build")
    else
        WR:Print(message)
    end
}

-- Apply build adjustments based on current build
function BuildAnalyzer:ApplyBuildAdjustments()
    if not currentBuild.matchedTemplate or not currentBuild.matchedTemplate.priority_modifications then
        return
    end
    
    local mods = currentBuild.matchedTemplate.priority_modifications
    
    -- Apply priority modifications to rotation
    if WR.Rotation then
        if mods.increase then
            for _, spellName in ipairs(mods.increase) do
                WR.Rotation:AdjustSpellPriority(spellName, 1.2) -- Increase by 20%
            end
        end
        
        if mods.decrease then
            for _, spellName in ipairs(mods.decrease) do
                WR.Rotation:AdjustSpellPriority(spellName, 0.8) -- Decrease by 20%
            end
        end
    end
    
    WR:Debug("Applied build adjustments from template: " .. currentBuild.matchedTemplate.name)
}

-- Get current build information
function BuildAnalyzer:GetCurrentBuild()
    return currentBuild
end

-- Get build suggestions
function BuildAnalyzer:GetBuildSuggestions()
    if not config.enableBuildSuggestions then
        return {}
    end
    
    return currentBuild.suggestedChanges
}

-- Get build summary
function BuildAnalyzer:GetBuildSummary()
    return currentBuild.buildSummary
}

-- Get build strong points
function BuildAnalyzer:GetBuildStrengths()
    return currentBuild.strongPoints
}

-- Get build weak points
function BuildAnalyzer:GetBuildWeaknesses()
    return currentBuild.weakPoints
}

-- Force a build rescan
function BuildAnalyzer:RescanBuild()
    self:ScanCurrentBuild()
end

-- Get configuration
function BuildAnalyzer:GetConfig()
    return config
end

-- Set configuration
function BuildAnalyzer:SetConfig(newConfig)
    if not newConfig then return end
    
    -- Store old config for reference
    local oldConfig = CopyTable(config)
    
    -- Update config
    for k, v in pairs(newConfig) do
        if config[k] ~= nil then  -- Only update existing settings
            config[k] = v
        end
    end
    
    -- Handle specific config changes
    if oldConfig.enableBuildScanning ~= config.enableBuildScanning then
        if config.enableBuildScanning then
            -- Set up periodic scanning
            C_Timer.NewTicker(config.scanFrequency, function()
                self:ScanCurrentBuild()
            end)
        end
    end
    
    -- Save configuration
    self:SaveSettings()
}

-- Handle build analyzer commands
function BuildAnalyzer:HandleCommand(args)
    if not args or args == "" then
        -- Show build summary
        self:ShowBuildSummary()
        return
    end
    
    local command, parameter = args:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or args:lower()
    
    if command == "scan" or command == "rescan" then
        -- Force a rescan
        self:RescanBuild()
        self:ShowBuildSummary()
    elseif command == "analyze" then
        -- Show detailed analysis
        self:ShowBuildAnalysis()
    elseif command == "suggestions" then
        -- Show suggestions
        self:ShowBuildSuggestions()
    elseif command == "templates" then
        -- Show available templates
        self:ShowAvailableTemplates()
    elseif command == "enable" then
        -- Enable build scanning
        config.enableBuildScanning = true
        self:SaveSettings()
        WR:Print("Build scanning enabled")
    elseif command == "disable" then
        -- Disable build scanning
        config.enableBuildScanning = false
        self:SaveSettings()
        WR:Print("Build scanning disabled")
    elseif command == "config" then
        -- Show/set configuration
        if parameter == "" then
            -- Show configuration
            self:ShowConfig()
        else
            -- Parse configuration setting
            local setting, value = parameter:match("^(%S+)%s+(.+)$")
            
            if setting and value and config[setting] ~= nil then
                -- Convert value based on setting type
                if type(config[setting]) == "boolean" then
                    value = value:lower()
                    config[setting] = (value == "true" or value == "yes" or value == "1" or value == "on")
                elseif type(config[setting]) == "number" then
                    config[setting] = tonumber(value) or config[setting]
                else
                    config[setting] = value
                end
                
                -- Save configuration
                self:SaveSettings()
                
                WR:Print("Set", setting, "to", tostring(config[setting]))
            else
                WR:Print("Unknown setting:", setting)
                WR:Print("Available settings:")
                
                for k, v in pairs(config) do
                    WR:Print("  -", k, "=", tostring(v), "(", type(v), ")")
                end
            end
        end
    else
        -- Unknown command
        WR:Print("Unknown build analyzer command:", command)
        WR:Print("Available commands: scan, analyze, suggestions, templates, enable, disable, config")
    end
end

-- Show build summary
function BuildAnalyzer:ShowBuildSummary()
    WR:Print("Current Build: " .. currentBuild.class .. " - " .. (currentBuild.specName or "Unknown"))
    
    if currentBuild.buildSummary then
        WR:Print("Summary: " .. currentBuild.buildSummary)
    end
    
    if currentBuild.matchedTemplate then
        WR:Print("Matched Template: " .. currentBuild.matchedTemplate.name .. 
                 " (Match: " .. string.format("%.0f", currentBuild.matchScore * 100) .. "%)")
    else
        WR:Print("No matching template found")
    end
    
    if #currentBuild.strongPoints > 0 then
        WR:Print("Strengths: " .. table.concat(currentBuild.strongPoints, ", "))
    end
    
    if #currentBuild.weakPoints > 0 then
        WR:Print("Weaknesses: " .. table.concat(currentBuild.weakPoints, ", "))
    end
    
    WR:Print("Use '/wr build analyze' for detailed analysis")
}

-- Show detailed build analysis
function BuildAnalyzer:ShowBuildAnalysis()
    WR:Print("======= Build Analysis =======")
    WR:Print("Class: " .. currentBuild.class)
    WR:Print("Spec: " .. (currentBuild.specName or "Unknown"))
    WR:Print("Talent String: " .. (currentBuild.talentString or "Unknown"))
    WR:Print("")
    
    if currentBuild.matchedTemplate then
        WR:Print("Matched Template: " .. currentBuild.matchedTemplate.name)
        WR:Print("Match Score: " .. string.format("%.0f", currentBuild.matchScore * 100) .. "%")
        WR:Print("Template Description: " .. currentBuild.matchedTemplate.description)
        WR:Print("")
    else
        WR:Print("No matching template found")
        WR:Print("")
    end
    
    WR:Print("--- Strengths ---")
    if #currentBuild.strongPoints > 0 then
        for i, strength in ipairs(currentBuild.strongPoints) do
            WR:Print(i .. ". " .. strength)
        end
    else
        WR:Print("No specific strengths identified")
    end
    
    WR:Print("")
    WR:Print("--- Weaknesses ---")
    if #currentBuild.weakPoints > 0 then
        for i, weakness in ipairs(currentBuild.weakPoints) do
            WR:Print(i .. ". " .. weakness)
        end
    else
        WR:Print("No specific weaknesses identified")
    end
    
    WR:Print("")
    WR:Print("--- Talent Choices ---")
    for tier, data in pairs(currentBuild.talentTiers) do
        WR:Print("Tier " .. tier .. ": Choice " .. data.choice)
    end
}

-- Show build suggestions
function BuildAnalyzer:ShowBuildSuggestions()
    WR:Print("======= Build Suggestions =======")
    
    if #currentBuild.suggestedChanges == 0 then
        WR:Print("No suggestions available. Your build appears optimal!")
        return
    end
    
    for i, suggestion in ipairs(currentBuild.suggestedChanges) do
        if suggestion.tier > 0 then
            WR:Print(i .. ". Change Tier " .. suggestion.tier .. " from Choice " .. 
                    suggestion.currentChoice .. " to Choice " .. suggestion.suggestedChoice)
            WR:Print("   Reason: " .. suggestion.reason)
        else
            -- General suggestion
            WR:Print(i .. ". " .. suggestion.reason)
        end
    end
}

-- Show available templates
function BuildAnalyzer:ShowAvailableTemplates()
    local className = currentBuild.class
    local specID = currentBuild.specID
    
    if not buildTemplates[className] or not buildTemplates[className][specID] or 
       #buildTemplates[className][specID] == 0 then
        WR:Print("No build templates available for " .. className .. " " .. (currentBuild.specName or "Unknown"))
        return
    end
    
    WR:Print("======= Available Build Templates =======")
    WR:Print("Class: " .. className .. " - " .. (currentBuild.specName or "Unknown"))
    
    for i, template in ipairs(buildTemplates[className][specID]) do
        WR:Print("")
        WR:Print(i .. ". " .. template.name)
        WR:Print("   Description: " .. template.description)
        
        -- Show priority modifications if available
        if template.priority_modifications then
            if template.priority_modifications.increase and #template.priority_modifications.increase > 0 then
                WR:Print("   Increases priority for: " .. table.concat(template.priority_modifications.increase, ", "))
            end
            
            if template.priority_modifications.decrease and #template.priority_modifications.decrease > 0 then
                WR:Print("   Decreases priority for: " .. table.concat(template.priority_modifications.decrease, ", "))
            end
        end
    end
}

-- Show configuration
function BuildAnalyzer:ShowConfig()
    WR:Print("Build Analyzer Configuration:")
    
    for k, v in pairs(config) do
        WR:Print(k .. ":", tostring(v))
    end
    
    WR:Print("")
    WR:Print("To change a setting, use: /wr build config setting value")
    WR:Print("Example: /wr build config enableBuildAnalysis true")
}

-- Create build analyzer UI
function BuildAnalyzer:CreateBuildAnalyzerUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsBuildUI", parent, "BackdropTemplate")
    frame:SetSize(700, 500)
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
    title:SetText("Windrunner Rotations Build Analyzer")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Overview", "Analysis", "Suggestions", "Templates"}
    
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
                BuildAnalyzer:UpdateOverviewTab(content)
            elseif tabName == "Analysis" then
                BuildAnalyzer:UpdateAnalysisTab(content)
            elseif tabName == "Suggestions" then
                BuildAnalyzer:UpdateSuggestionsTab(content)
            elseif tabName == "Templates" then
                BuildAnalyzer:UpdateTemplatesTab(content)
            end
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Function to update overview tab
    function BuildAnalyzer:UpdateOverviewTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create summary frame
        local summaryFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        summaryFrame:SetSize(content:GetWidth(), 100)
        summaryFrame:SetPoint("TOP", content, "TOP", 0, 0)
        summaryFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        summaryFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Class and spec
        local classText = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        classText:SetPoint("TOPLEFT", summaryFrame, "TOPLEFT", 15, -15)
        classText:SetText(currentBuild.class .. " - " .. (currentBuild.specName or "Unknown"))
        
        -- Build summary
        local summaryText = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        summaryText:SetPoint("TOPLEFT", classText, "BOTTOMLEFT", 0, -10)
        summaryText:SetText("Build Summary: " .. (currentBuild.buildSummary or "Unknown"))
        
        -- Match info
        local matchText = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        matchText:SetPoint("TOPLEFT", summaryText, "BOTTOMLEFT", 0, -10)
        
        if currentBuild.matchedTemplate then
            matchText:SetText("Matched Template: " .. currentBuild.matchedTemplate.name .. 
                           " (" .. string.format("%.0f", currentBuild.matchScore * 100) .. "% match)")
        else
            matchText:SetText("No matching template found")
        end
        
        -- Create strengths frame
        local strengthsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        strengthsFrame:SetSize(content:GetWidth() / 2 - 5, 150)
        strengthsFrame:SetPoint("TOPLEFT", summaryFrame, "BOTTOMLEFT", 0, -10)
        strengthsFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        strengthsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local strengthsTitle = strengthsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        strengthsTitle:SetPoint("TOPLEFT", strengthsFrame, "TOPLEFT", 15, -15)
        strengthsTitle:SetText("Build Strengths")
        
        -- List strengths
        local strengthY = -40
        if #currentBuild.strongPoints > 0 then
            for i, strength in ipairs(currentBuild.strongPoints) do
                local strengthText = strengthsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                strengthText:SetPoint("TOPLEFT", strengthsFrame, "TOPLEFT", 20, strengthY)
                strengthText:SetText("• " .. strength)
                
                strengthY = strengthY - 20
            end
        else
            local noStrengthsText = strengthsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noStrengthsText:SetPoint("TOPLEFT", strengthsFrame, "TOPLEFT", 20, strengthY)
            noStrengthsText:SetText("No specific strengths identified")
        end
        
        -- Create weaknesses frame
        local weaknessesFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        weaknessesFrame:SetSize(content:GetWidth() / 2 - 5, 150)
        weaknessesFrame:SetPoint("TOPRIGHT", summaryFrame, "BOTTOMRIGHT", 0, -10)
        weaknessesFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        weaknessesFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local weaknessesTitle = weaknessesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        weaknessesTitle:SetPoint("TOPLEFT", weaknessesFrame, "TOPLEFT", 15, -15)
        weaknessesTitle:SetText("Build Weaknesses")
        
        -- List weaknesses
        local weaknessY = -40
        if #currentBuild.weakPoints > 0 then
            for i, weakness in ipairs(currentBuild.weakPoints) do
                local weaknessText = weaknessesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                weaknessText:SetPoint("TOPLEFT", weaknessesFrame, "TOPLEFT", 20, weaknessY)
                weaknessText:SetText("• " .. weakness)
                
                weaknessY = weaknessY - 20
            end
        else
            local noWeaknessesText = weaknessesFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noWeaknessesText:SetPoint("TOPLEFT", weaknessesFrame, "TOPLEFT", 20, weaknessY)
            noWeaknessesText:SetText("No specific weaknesses identified")
        end
        
        -- Create talent summary frame
        local talentFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        talentFrame:SetSize(content:GetWidth(), 100)
        talentFrame:SetPoint("BOTTOM", content, "BOTTOM", 0, 0)
        talentFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        talentFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local talentTitle = talentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        talentTitle:SetPoint("TOPLEFT", talentFrame, "TOPLEFT", 15, -15)
        talentTitle:SetText("Talent Summary")
        
        -- Create a grid of talent choices
        local talentGrid = CreateFrame("Frame", nil, talentFrame)
        talentGrid:SetSize(talentFrame:GetWidth() - 30, 60)
        talentGrid:SetPoint("TOP", talentTitle, "BOTTOM", 0, -5)
        
        local tierWidth = talentGrid:GetWidth() / TALENT_SCAN_DEPTH
        
        for tier = 1, TALENT_SCAN_DEPTH do
            local choice = currentBuild.talentChoices[tier]
            
            -- Tier number
            local tierText = talentGrid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tierText:SetPoint("TOP", talentGrid, "TOPLEFT", (tier - 0.5) * tierWidth, 0)
            tierText:SetText("Tier " .. tier)
            
            -- Choice
            local choiceText = talentGrid:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            choiceText:SetPoint("TOP", tierText, "BOTTOM", 0, -5)
            choiceText:SetText("Choice " .. (choice or "?"))
            
            -- Visual indicator of match/mismatch with template
            if currentBuild.matchedTemplate and currentBuild.matchedTemplate.talents then
                local templateChoice = tonumber(currentBuild.matchedTemplate.talents:sub(tier,tier))
                local matchTexture = talentGrid:CreateTexture(nil, "ARTWORK")
                matchTexture:SetSize(16, 16)
                matchTexture:SetPoint("TOP", choiceText, "BOTTOM", 0, -5)
                
                if choice == templateChoice then
                    -- Match
                    matchTexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                else
                    -- Mismatch
                    matchTexture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
                end
            end
        end
        
        -- Create action buttons
        local rescanButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        rescanButton:SetSize(100, 30)
        rescanButton:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 20, 10)
        rescanButton:SetText("Rescan")
        rescanButton:SetScript("OnClick", function()
            self:RescanBuild()
            self:UpdateOverviewTab(content)
        end)
    end
    
    -- Function to update analysis tab
    function BuildAnalyzer:UpdateAnalysisTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create header
        local headerFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        headerFrame:SetSize(content:GetWidth(), 50)
        headerFrame:SetPoint("TOP", content, "TOP", 0, 0)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        headerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local headerTitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerTitle:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 15, -15)
        headerTitle:SetText("Build Analysis")
        
        -- Create scrollframe for detailed analysis
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 60)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add detailed analysis content
        local y = 0
        
        -- Class and spec
        local classText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        classText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        classText:SetText(currentBuild.class .. " - " .. (currentBuild.specName or "Unknown"))
        
        y = y - 30
        
        -- Talent string
        local talentText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        talentText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        talentText:SetText("Talent String: " .. (currentBuild.talentString or "Unknown"))
        
        y = y - 30
        
        -- Matched template section
        local templateHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        templateHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        templateHeader:SetText("Template Match")
        
        y = y - 20
        
        if currentBuild.matchedTemplate then
            local templateName = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            templateName:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            templateName:SetText("Matched: " .. currentBuild.matchedTemplate.name)
            
            y = y - 20
            
            local templateScore = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            templateScore:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            templateScore:SetText("Match Score: " .. string.format("%.0f", currentBuild.matchScore * 100) .. "%")
            
            y = y - 20
            
            local templateDesc = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            templateDesc:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            templateDesc:SetText("Description: " .. currentBuild.matchedTemplate.description)
            
            y = y - 30
        else
            local noTemplateText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noTemplateText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            noTemplateText:SetText("No matching template found")
            
            y = y - 30
        end
        
        -- Strengths section
        local strengthsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        strengthsHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        strengthsHeader:SetText("Build Strengths")
        
        y = y - 20
        
        if #currentBuild.strongPoints > 0 then
            for i, strength in ipairs(currentBuild.strongPoints) do
                local strengthText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                strengthText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
                strengthText:SetText(i .. ". " .. strength)
                
                y = y - 20
            end
        else
            local noStrengthsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noStrengthsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            noStrengthsText:SetText("No specific strengths identified")
            
            y = y - 20
        end
        
        y = y - 10
        
        -- Weaknesses section
        local weaknessesHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        weaknessesHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        weaknessesHeader:SetText("Build Weaknesses")
        
        y = y - 20
        
        if #currentBuild.weakPoints > 0 then
            for i, weakness in ipairs(currentBuild.weakPoints) do
                local weaknessText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                weaknessText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
                weaknessText:SetText(i .. ". " .. weakness)
                
                y = y - 20
            end
        else
            local noWeaknessesText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            noWeaknessesText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            noWeaknessesText:SetText("No specific weaknesses identified")
            
            y = y - 20
        end
        
        y = y - 10
        
        -- Talent choices section
        local talentHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        talentHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        talentHeader:SetText("Talent Choices")
        
        y = y - 20
        
        for tier, data in pairs(currentBuild.talentTiers) do
            local talentText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            talentText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
            talentText:SetText("Tier " .. tier .. ": Choice " .. data.choice)
            
            -- If we have a matched template, show if this choice matches
            if currentBuild.matchedTemplate and currentBuild.matchedTemplate.talents then
                local templateChoice = tonumber(currentBuild.matchedTemplate.talents:sub(tier,tier))
                
                if data.choice == templateChoice then
                    local matchText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    matchText:SetPoint("LEFT", talentText, "RIGHT", 20, 0)
                    matchText:SetText("(Matches template)")
                    matchText:SetTextColor(0, 1, 0)
                else
                    local mismatchText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    mismatchText:SetPoint("LEFT", talentText, "RIGHT", 20, 0)
                    mismatchText:SetText("(Template recommends choice " .. templateChoice .. ")")
                    mismatchText:SetTextColor(1, 0.5, 0)
                end
            end
            
            y = y - 20
        end
        
        -- Set scrollchild height
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Function to update suggestions tab
    function BuildAnalyzer:UpdateSuggestionsTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create header
        local headerFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        headerFrame:SetSize(content:GetWidth(), 50)
        headerFrame:SetPoint("TOP", content, "TOP", 0, 0)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        headerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local headerTitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerTitle:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 15, -15)
        headerTitle:SetText("Build Suggestions")
        
        -- Create scrollframe for suggestions
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 60)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add suggestions content
        local y = 0
        
        if #currentBuild.suggestedChanges == 0 then
            local noSuggestionsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            noSuggestionsText:SetPoint("CENTER", scrollChild, "TOP", 0, -100)
            noSuggestionsText:SetText("No suggestions available - your build appears optimal!")
            
            scrollChild:SetHeight(200)
            return
        end
        
        -- Add each suggestion
        for i, suggestion in ipairs(currentBuild.suggestedChanges) do
            local suggestionFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            suggestionFrame:SetSize(scrollChild:GetWidth() - 20, 70)
            suggestionFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            suggestionFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            suggestionFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            if suggestion.tier > 0 then
                -- Specific talent change suggestion
                local suggestionTitle = suggestionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                suggestionTitle:SetPoint("TOPLEFT", suggestionFrame, "TOPLEFT", 15, -15)
                suggestionTitle:SetText(i .. ". Change Tier " .. suggestion.tier .. " from Choice " .. 
                                       suggestion.currentChoice .. " to Choice " .. suggestion.suggestedChoice)
                
                local reasonText = suggestionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                reasonText:SetPoint("TOPLEFT", suggestionTitle, "BOTTOMLEFT", 5, -5)
                reasonText:SetText("Reason: " .. suggestion.reason)
            else
                -- General suggestion
                local suggestionTitle = suggestionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                suggestionTitle:SetPoint("TOPLEFT", suggestionFrame, "TOPLEFT", 15, -15)
                suggestionTitle:SetText(i .. ". General Suggestion")
                
                local reasonText = suggestionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                reasonText:SetPoint("TOPLEFT", suggestionTitle, "BOTTOMLEFT", 5, -5)
                reasonText:SetText(suggestion.reason)
            end
            
            y = y - suggestionFrame:GetHeight() - 10
        }
        
        -- Set scrollchild height
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Function to update templates tab
    function BuildAnalyzer:UpdateTemplatesTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create header
        local headerFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        headerFrame:SetSize(content:GetWidth(), 50)
        headerFrame:SetPoint("TOP", content, "TOP", 0, 0)
        headerFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        headerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        local headerTitle = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerTitle:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 15, -15)
        headerTitle:SetText("Available Build Templates")
        
        local className = currentBuild.class
        local specID = currentBuild.specID
        
        if not buildTemplates[className] or not buildTemplates[className][specID] or 
           #buildTemplates[className][specID] == 0 then
            -- No templates available
            local noTemplatesText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            noTemplatesText:SetPoint("CENTER", content, "CENTER", 0, 0)
            noTemplatesText:SetText("No build templates available for " .. className .. " " .. (currentBuild.specName or "Unknown"))
            
            return
        end
        
        -- Create scrollframe for templates
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight() - 60)
        scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -5)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Add templates
        local y = 0
        
        for i, template in ipairs(buildTemplates[className][specID]) do
            local templateFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            templateFrame:SetSize(scrollChild:GetWidth() - 20, 100)
            templateFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            templateFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            templateFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Highlight current template if matched
            if currentBuild.matchedTemplate and currentBuild.matchedTemplate.name == template.name then
                templateFrame:SetBackdropBorderColor(0, 1, 0)
            end
            
            -- Template name
            local templateName = templateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            templateName:SetPoint("TOPLEFT", templateFrame, "TOPLEFT", 15, -15)
            templateName:SetText(i .. ". " .. template.name)
            
            -- Template description
            local templateDesc = templateFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            templateDesc:SetPoint("TOPLEFT", templateName, "BOTTOMLEFT", 5, -5)
            templateDesc:SetPoint("RIGHT", templateFrame, "RIGHT", -15, 0)
            templateDesc:SetJustifyH("LEFT")
            templateDesc:SetText("Description: " .. template.description)
            
            -- Priority modifications
            local mods = template.priority_modifications
            if mods then
                local y2 = -50
                
                if mods.increase and #mods.increase > 0 then
                    local increaseText = templateFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    increaseText:SetPoint("TOPLEFT", templateFrame, "TOPLEFT", 20, y2)
                    increaseText:SetText("Increased Priority: " .. table.concat(mods.increase, ", "))
                    increaseText:SetTextColor(0, 1, 0)
                    
                    y2 = y2 - 15
                end
                
                if mods.decrease and #mods.decrease > 0 then
                    local decreaseText = templateFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    decreaseText:SetPoint("TOPLEFT", templateFrame, "TOPLEFT", 20, y2)
                    decreaseText:SetText("Decreased Priority: " .. table.concat(mods.decrease, ", "))
                    decreaseText:SetTextColor(1, 0.5, 0)
                    
                    y2 = y2 - 15
                end
                
                -- Adjust frame height if needed
                if y2 < -70 then
                    templateFrame:SetHeight(math.abs(y2) + 20)
                end
            end
            
            y = y - templateFrame:GetHeight() - 10
        }
        
        -- Set scrollchild height
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Update first tab content
    BuildAnalyzer:UpdateOverviewTab(tabContents[1])
    
    -- Hide by default
    frame:Hide()
    
    return frame
}

-- Initialize the module
BuildAnalyzer:Initialize()

return BuildAnalyzer