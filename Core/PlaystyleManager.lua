local addonName, WR = ...

-- PlaystyleManager module for handling different playstyle profiles
local PlaystyleManager = {}
WR.PlaystyleManager = PlaystyleManager

-- Import constants
local CLASS, SPEC
if WR.ClassKnowledge then
    CLASS = WR.ClassKnowledge.CLASS
    SPEC = WR.ClassKnowledge.SPEC
end

-- Local variables
local currentClass, currentSpec
local currentProfile = "Standard"
local customProfile = {}
local profileSettings = {}
local presetProfiles = {}

-- Standard playstyle profiles
local standardProfiles = {
    ["Beginner"] = {
        description = "Simplified rotation with fewer buttons",
        ability_count = "reduced",
        prioritize = "consistency",
        cooldown_usage = "conservative",
        defensives_usage = "proactive",
        movement_style = "simplified",
        rotation_complexity = 1,  -- 1-5 scale
        resource_strategy = "conservative",
        mod_factors = {
            ability_pruning = 0.7,  -- How aggressively to prune abilities (0-1)
            consistency_weight = 1.3,  -- How much to weight consistent performance over peak performance
            cooldown_threshold = 0.8,  -- How full cooldowns need to be before using (0-1)
            defensive_threshold = 0.7  -- Health % to trigger defensive abilities
        }
    },
    
    ["Standard"] = {
        description = "Balanced rotation suitable for most content",
        ability_count = "standard",
        prioritize = "balanced",
        cooldown_usage = "optimal",
        defensives_usage = "balanced",
        movement_style = "standard",
        rotation_complexity = 3,  -- 1-5 scale
        resource_strategy = "balanced",
        mod_factors = {
            ability_pruning = 0.0,  -- No pruning
            consistency_weight = 1.0,  -- Balanced consistency/peak performance
            cooldown_threshold = 0.6,  -- Cooldown usage threshold at 60%
            defensive_threshold = 0.6  -- Health % to trigger defensive abilities
        }
    },
    
    ["Advanced"] = {
        description = "Complex rotation for experienced players",
        ability_count = "full",
        prioritize = "min-max",
        cooldown_usage = "aggressive",
        defensives_usage = "reactive",
        movement_style = "advanced",
        rotation_complexity = 5,  -- 1-5 scale
        resource_strategy = "aggressive",
        mod_factors = {
            ability_pruning = -0.2,  -- Actually add some advanced abilities
            consistency_weight = 0.8,  -- Favor peak performance over consistency
            cooldown_threshold = 0.4,  -- Aggressive cooldown usage at 40%
            defensive_threshold = 0.4  -- Health % to trigger defensive abilities
        }
    },
    
    ["Custom"] = {
        description = "Fully customized settings",
        -- Remaining settings will be filled from customProfile
        mod_factors = {}
    }
}

-- Configuration
local config = {
    enablePlaystyleProfiles = true,
    defaultProfile = "Standard",
    showProfileRecommendations = true,
    autoSwitchProfilesByContent = false,
    profileRecommendationFrequency = 300,  -- Seconds between recommendations
    automaticAdjustments = true
}

-- Initialize the PlaystyleManager
function PlaystyleManager:Initialize()
    -- Load saved settings
    if WindrunnerRotationsDB and WindrunnerRotationsDB.PlaystyleManager then
        local savedConfig = WindrunnerRotationsDB.PlaystyleManager
        for k, v in pairs(savedConfig) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
        
        -- Load saved custom profile
        if WindrunnerRotationsDB.PlaystyleManager.customProfile then
            customProfile = CopyTable(WindrunnerRotationsDB.PlaystyleManager.customProfile)
        end
        
        -- Load saved current profile
        if WindrunnerRotationsDB.PlaystyleManager.currentProfile then
            currentProfile = WindrunnerRotationsDB.PlaystyleManager.currentProfile
        end
    end
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_LOGOUT")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            PlaystyleManager:DetectClassAndSpec()
            PlaystyleManager:InitializeProfiles()
            PlaystyleManager:ApplyProfile(currentProfile)
        elseif event == "PLAYER_LOGOUT" then
            PlaystyleManager:SaveSettings()
        elseif event == "CHALLENGE_MODE_START" or event == "ENCOUNTER_START" then
            -- Auto-switch profiles if enabled
            if config.autoSwitchProfilesByContent then
                PlaystyleManager:AutoSwitchProfileForContent(event, ...)
            end
        end
    end)
    
    -- Set up periodic profile recommendations if enabled
    if config.showProfileRecommendations and config.profileRecommendationFrequency > 0 then
        C_Timer.NewTicker(config.profileRecommendationFrequency, function()
            PlaystyleManager:SuggestProfileBasedOnPerformance()
        end)
    end
    
    -- Initial detection and setup
    self:DetectClassAndSpec()
    self:InitializeProfiles()
    self:ApplyProfile(currentProfile)
    
    -- Integration with rotation enhancer
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RegisterPlaystyleManager(self)
    end
    
    WR:Debug("PlaystyleManager module initialized with profile: " .. currentProfile)
end

-- Save settings
function PlaystyleManager:SaveSettings()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.PlaystyleManager = CopyTable(config)
    
    -- Save custom profile
    WindrunnerRotationsDB.PlaystyleManager.customProfile = CopyTable(customProfile)
    
    -- Save current profile
    WindrunnerRotationsDB.PlaystyleManager.currentProfile = currentProfile
}

-- Detect player class and specialization
function PlaystyleManager:DetectClassAndSpec()
    currentClass = select(2, UnitClass("player"))
    currentSpec = GetSpecialization()
    
    WR:Debug("Detected class: " .. currentClass .. ", spec: " .. (currentSpec or "None"))
}

-- Initialize profiles for current class/spec
function PlaystyleManager:InitializeProfiles()
    -- Start with standard profiles
    presetProfiles = CopyTable(standardProfiles)
    
    -- Add class/spec-specific profiles if available
    self:AddClassSpecificProfiles()
    
    -- Setup custom profile with defaults if empty
    if not customProfile.ability_count then
        customProfile = CopyTable(standardProfiles["Standard"])
        customProfile.description = "Custom profile for " .. currentClass .. " " .. 
                                   (GetSpecializationInfo(currentSpec) or "Unknown")
    end
    
    -- Update the Custom preset with custom settings
    for k, v in pairs(customProfile) do
        presetProfiles["Custom"][k] = v
    end
    
    WR:Debug("Initialized profiles for " .. currentClass .. " " .. (currentSpec or "Unknown"))
}

-- Add class/spec-specific profiles
function PlaystyleManager:AddClassSpecificProfiles()
    local classKey = currentClass .. (currentSpec or "")
    
    -- Call the appropriate method for the current class/spec if it exists
    local methodName = "AddProfiles_" .. classKey
    if self[methodName] then
        self[methodName](self)
    end
}

-- Apply a playstyle profile
function PlaystyleManager:ApplyProfile(profileName)
    if not presetProfiles[profileName] then
        WR:Debug("Invalid profile name: " .. profileName)
        return false
    end
    
    -- Store current profile
    currentProfile = profileName
    
    -- Get profile settings
    profileSettings = CopyTable(presetProfiles[profileName])
    
    -- Apply profile settings to various systems
    self:ApplySettingsToRotation()
    self:ApplySettingsToResources()
    self:ApplySettingsToCooldowns()
    self:ApplySettingsToDefensives()
    
    -- Notify other systems
    if WR.RotationEnhancer then
        WR.RotationEnhancer:PlaystyleChanged(profileName, profileSettings)
    end
    
    -- Save settings
    self:SaveSettings()
    
    WR:Debug("Applied profile: " .. profileName)
    return true
end

-- Apply settings to rotation system
function PlaystyleManager:ApplySettingsToRotation()
    if not WR.Rotation then return end
    
    -- Apply rotation complexity settings
    local complexityLevel = profileSettings.rotation_complexity or 3
    
    -- Apply ability pruning
    local pruningFactor = (profileSettings.mod_factors and profileSettings.mod_factors.ability_pruning) or 0
    
    -- Apply consistency weighting
    local consistencyWeight = (profileSettings.mod_factors and profileSettings.mod_factors.consistency_weight) or 1
    
    -- Example application to rotation system
    WR.Rotation:SetRotationComplexity(complexityLevel)
    WR.Rotation:SetAbilityPruningFactor(pruningFactor)
    WR.Rotation:SetConsistencyWeight(consistencyWeight)
    
    WR:Debug("Applied rotation settings from profile: " .. currentProfile)
}

-- Apply settings to resource management
function PlaystyleManager:ApplySettingsToResources()
    if not WR.ResourceOptimizer then return end
    
    -- Apply resource strategy
    local resourceStrategy = profileSettings.resource_strategy or "balanced"
    
    -- Set resource strategy
    WR.ResourceOptimizer:SetStrategy(resourceStrategy)
    
    WR:Debug("Applied resource settings from profile: " .. currentProfile)
}

-- Apply settings to cooldown usage
function PlaystyleManager:ApplySettingsToCooldowns()
    if not WR.Rotation then return end
    
    -- Apply cooldown usage style
    local cooldownUsage = profileSettings.cooldown_usage or "optimal"
    local cooldownThreshold = (profileSettings.mod_factors and profileSettings.mod_factors.cooldown_threshold) or 0.6
    
    -- Map style to behavior
    local cooldownStyle = {
        conservative = {
            threshold = 0.8,
            require_burst_phase = true,
            require_multiple_targets_for_aoe = true
        },
        optimal = {
            threshold = 0.6,
            require_burst_phase = false,
            require_multiple_targets_for_aoe = false
        },
        aggressive = {
            threshold = 0.4,
            require_burst_phase = false,
            require_multiple_targets_for_aoe = false
        }
    }
    
    -- Get style settings
    local style = cooldownStyle[cooldownUsage] or cooldownStyle.optimal
    
    -- Override threshold with profile-specific setting if available
    style.threshold = cooldownThreshold
    
    -- Apply to rotation system
    WR.Rotation:SetCooldownStyle(style)
    
    WR:Debug("Applied cooldown settings from profile: " .. currentProfile)
}

-- Apply settings to defensive usage
function PlaystyleManager:ApplySettingsToDefensives()
    if not WR.Rotation then return end
    
    -- Apply defensive usage style
    local defensivesUsage = profileSettings.defensives_usage or "balanced"
    local defensiveThreshold = (profileSettings.mod_factors and profileSettings.mod_factors.defensive_threshold) or 0.6
    
    -- Map style to behavior
    local defensiveStyle = {
        proactive = {
            threshold = 0.7,
            use_preventatively = true,
            prioritize_defensives = true
        },
        balanced = {
            threshold = 0.6,
            use_preventatively = false,
            prioritize_defensives = false
        },
        reactive = {
            threshold = 0.4,
            use_preventatively = false,
            prioritize_defensives = false
        }
    }
    
    -- Get style settings
    local style = defensiveStyle[defensivesUsage] or defensiveStyle.balanced
    
    -- Override threshold with profile-specific setting if available
    style.threshold = defensiveThreshold
    
    -- Apply to rotation system
    WR.Rotation:SetDefensiveStyle(style)
    
    WR:Debug("Applied defensive settings from profile: " .. currentProfile)
}

-- Get current profile
function PlaystyleManager:GetCurrentProfile()
    return currentProfile, presetProfiles[currentProfile]
end

-- Get available profiles
function PlaystyleManager:GetAvailableProfiles()
    local profiles = {}
    
    for name, profile in pairs(presetProfiles) do
        table.insert(profiles, {
            name = name,
            description = profile.description
        })
    end
    
    return profiles
end

-- Get current profile settings
function PlaystyleManager:GetProfileSettings()
    return profileSettings
end

-- Update custom profile settings
function PlaystyleManager:UpdateCustomProfile(settings)
    if not settings then return false end
    
    -- Update custom profile
    for k, v in pairs(settings) do
        customProfile[k] = v
    end
    
    -- Update preset profile
    for k, v in pairs(customProfile) do
        presetProfiles["Custom"][k] = v
    end
    
    -- Apply if currently using custom profile
    if currentProfile == "Custom" then
        self:ApplyProfile("Custom")
    end
    
    -- Save settings
    self:SaveSettings()
    
    WR:Debug("Updated custom profile settings")
    return true
end

-- Reset custom profile to standard
function PlaystyleManager:ResetCustomProfile()
    customProfile = CopyTable(standardProfiles["Standard"])
    customProfile.description = "Custom profile for " .. currentClass .. " " .. 
                               (GetSpecializationInfo(currentSpec) or "Unknown")
    
    -- Update preset profile
    for k, v in pairs(customProfile) do
        presetProfiles["Custom"][k] = v
    end
    
    -- Apply if currently using custom profile
    if currentProfile == "Custom" then
        self:ApplyProfile("Custom")
    end
    
    -- Save settings
    self:SaveSettings()
    
    WR:Debug("Reset custom profile to standard settings")
    return true
end

-- Automatically switch profile based on content
function PlaystyleManager:AutoSwitchProfileForContent(event, ...)
    local recommendedProfile = "Standard" -- Default
    
    if event == "CHALLENGE_MODE_START" then
        -- Mythic+ dungeon started
        recommendedProfile = "Advanced" -- Higher complexity for M+
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, raidSize = ...
        
        -- Check raid difficulty
        if difficultyID >= 15 then
            -- Mythic raid
            recommendedProfile = "Advanced"
        elseif difficultyID >= 14 then
            -- Heroic raid
            recommendedProfile = "Standard"
        else
            -- Normal or LFR raid
            recommendedProfile = "Beginner"
        end
    end
    
    -- Apply recommended profile if different
    if recommendedProfile ~= currentProfile then
        self:ApplyProfile(recommendedProfile)
        
        -- Notify user
        WR:Print("Automatically switched to " .. recommendedProfile .. " profile for current content")
    end
}

-- Suggest profile based on player performance
function PlaystyleManager:SuggestProfileBasedOnPerformance()
    -- Skip if disabled
    if not config.showProfileRecommendations then
        return
    end
    
    -- In a real implementation, this would analyze performance data
    -- from the Learning System and suggest a profile based on player skill level
    
    -- For demonstration, we'll use a placeholder logic
    local playerSkillLevel = self:EstimatePlayerSkill()
    local recommendedProfile = "Standard" -- Default
    
    if playerSkillLevel < 2 then
        recommendedProfile = "Beginner"
    elseif playerSkillLevel > 4 then
        recommendedProfile = "Advanced"
    end
    
    -- Only suggest a different profile
    if recommendedProfile ~= currentProfile then
        -- Notify user
        WR:Print("Based on your performance, you might want to try the " .. recommendedProfile .. " profile.")
        WR:Print("Type '/wr playstyle " .. string.lower(recommendedProfile) .. "' to switch.")
    end
}

-- Estimate player skill level (1-5 scale)
function PlaystyleManager:EstimatePlayerSkill()
    -- In a real implementation, this would use performance metrics from the Learning System
    -- For demonstration, we'll use a placeholder logic
    
    local skillLevel = 3 -- Default: average
    
    -- Check for relevant metrics if available
    if WR.LearningSystem and WR.LearningSystem.GetPerformanceMetrics then
        local metrics = WR.LearningSystem.GetPerformanceMetrics()
        
        if metrics and metrics.averageDamage and metrics.optimalDamage then
            -- Calculate efficiency as percentage of optimal damage achieved
            local efficiency = metrics.averageDamage / metrics.optimalDamage
            
            -- Map to skill level
            if efficiency > 0.95 then
                skillLevel = 5 -- Expert
            elseif efficiency > 0.85 then
                skillLevel = 4 -- Advanced
            elseif efficiency > 0.7 then
                skillLevel = 3 -- Intermediate
            elseif efficiency > 0.5 then
                skillLevel = 2 -- Beginner
            else
                skillLevel = 1 -- Novice
            end
        end
    end
    
    return skillLevel
end

-- Get configuration
function PlaystyleManager:GetConfig()
    return config
end

-- Set configuration
function PlaystyleManager:SetConfig(newConfig)
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
    if oldConfig.enablePlaystyleProfiles ~= config.enablePlaystyleProfiles then
        if config.enablePlaystyleProfiles then
            -- Re-apply current profile
            self:ApplyProfile(currentProfile)
        end
    end
    
    if oldConfig.showProfileRecommendations ~= config.showProfileRecommendations or
       oldConfig.profileRecommendationFrequency ~= config.profileRecommendationFrequency then
        -- Reset ticker
        if config.showProfileRecommendations and config.profileRecommendationFrequency > 0 then
            C_Timer.NewTicker(config.profileRecommendationFrequency, function()
                PlaystyleManager:SuggestProfileBasedOnPerformance()
            end)
        end
    end
    
    -- Save configuration
    self:SaveSettings()
}

-- Handle playstyle manager commands
function PlaystyleManager:HandleCommand(args)
    if not args or args == "" then
        -- Show current profile
        self:ShowCurrentProfile()
        return
    end
    
    local command, parameter = args:match("^(%S+)%s*(.*)$")
    command = command and command:lower() or args:lower()
    
    -- Check if command is a profile name
    for profileName, _ in pairs(presetProfiles) do
        if command == profileName:lower() then
            -- Switch to profile
            if self:ApplyProfile(profileName) then
                WR:Print("Switched to " .. profileName .. " profile")
            else
                WR:Print("Failed to switch to " .. profileName .. " profile")
            end
            return
        end
    end
    
    -- Handle other commands
    if command == "list" or command == "profiles" then
        -- List available profiles
        self:ShowAvailableProfiles()
    elseif command == "info" or command == "details" then
        -- Show detailed info about a profile
        if parameter ~= "" then
            self:ShowProfileDetails(parameter)
        else
            self:ShowProfileDetails(currentProfile)
        end
    elseif command == "custom" then
        if parameter == "reset" then
            -- Reset custom profile
            self:ResetCustomProfile()
            WR:Print("Reset custom profile to standard settings")
        else
            -- Edit custom profile
            self:EditCustomProfile(parameter)
        end
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
        WR:Print("Unknown playstyle command:", command)
        WR:Print("Available commands: <profile_name>, list, info [profile], custom [reset], config")
        WR:Print("Available profiles: " .. self:GetProfileListString())
    end
end

-- Get profile list as string
function PlaystyleManager:GetProfileListString()
    local profileList = ""
    
    for profileName, _ in pairs(presetProfiles) do
        profileList = profileList .. profileName .. ", "
    end
    
    return profileList:sub(1, -3) -- Remove trailing comma and space
end

-- Show current profile
function PlaystyleManager:ShowCurrentProfile()
    local _, profile = self:GetCurrentProfile()
    
    WR:Print("Current profile: " .. currentProfile)
    WR:Print("Description: " .. profile.description)
    WR:Print("Type '/wr playstyle list' to see available profiles")
}

-- Show available profiles
function PlaystyleManager:ShowAvailableProfiles()
    WR:Print("Available playstyle profiles:")
    
    for _, profile in ipairs(self:GetAvailableProfiles()) do
        local profileText = profile.name
        
        if profile.name == currentProfile then
            profileText = profileText .. " (current)"
        end
        
        WR:Print("- " .. profileText .. ": " .. profile.description)
    end
    
    WR:Print("Type '/wr playstyle <profile_name>' to switch profiles")
}

-- Show profile details
function PlaystyleManager:ShowProfileDetails(profileName)
    -- Normalize profile name using case-insensitive match
    local matchedName
    for name, _ in pairs(presetProfiles) do
        if name:lower() == profileName:lower() then
            matchedName = name
            break
        end
    end
    
    if not matchedName or not presetProfiles[matchedName] then
        WR:Print("Unknown profile: " .. profileName)
        WR:Print("Available profiles: " .. self:GetProfileListString())
        return
    end
    
    local profile = presetProfiles[matchedName]
    
    WR:Print("=== " .. matchedName .. " Profile ===")
    WR:Print("Description: " .. profile.description)
    WR:Print("Ability Count: " .. (profile.ability_count or "N/A"))
    WR:Print("Priority Focus: " .. (profile.prioritize or "N/A"))
    WR:Print("Cooldown Usage: " .. (profile.cooldown_usage or "N/A"))
    WR:Print("Defensive Usage: " .. (profile.defensives_usage or "N/A"))
    WR:Print("Movement Style: " .. (profile.movement_style or "N/A"))
    WR:Print("Rotation Complexity: " .. (profile.rotation_complexity or "N/A") .. " (1-5 scale)")
    WR:Print("Resource Strategy: " .. (profile.resource_strategy or "N/A"))
    
    if profile.mod_factors then
        WR:Print("Modification Factors:")
        for k, v in pairs(profile.mod_factors) do
            WR:Print("  - " .. k .. ": " .. tostring(v))
        end
    end
}

-- Edit custom profile
function PlaystyleManager:EditCustomProfile(paramString)
    if not paramString or paramString == "" then
        -- Show custom profile details
        self:ShowProfileDetails("Custom")
        WR:Print("To edit the custom profile, use '/wr playstyle custom <setting> <value>'")
        WR:Print("Example: /wr playstyle custom rotation_complexity 4")
        return
    end
    
    local setting, value = paramString:match("^(%S+)%s+(.+)$")
    
    if not setting or not value then
        WR:Print("Invalid format. Use '/wr playstyle custom <setting> <value>'")
        return
    end
    
    -- Handle special case for mod_factors
    if setting:find("mod_factors%.") then
        local factor = setting:match("mod_factors%.(.+)")
        
        if factor then
            -- Ensure mod_factors table exists
            customProfile.mod_factors = customProfile.mod_factors or {}
            
            -- Convert value based on expected type
            local numValue = tonumber(value)
            if numValue then
                customProfile.mod_factors[factor] = numValue
            else
                customProfile.mod_factors[factor] = value
            end
            
            -- Update the custom profile
            self:UpdateCustomProfile(customProfile)
            
            WR:Print("Set custom profile " .. setting .. " to " .. value)
            return
        end
    end
    
    -- Handle regular settings
    if customProfile[setting] ~= nil then
        -- Convert value based on current type
        if type(customProfile[setting]) == "boolean" then
            value = value:lower()
            customProfile[setting] = (value == "true" or value == "yes" or value == "1" or value == "on")
        elseif type(customProfile[setting]) == "number" then
            customProfile[setting] = tonumber(value) or customProfile[setting]
        else
            customProfile[setting] = value
        end
        
        -- Update the custom profile
        self:UpdateCustomProfile(customProfile)
        
        WR:Print("Set custom profile " .. setting .. " to " .. tostring(customProfile[setting]))
    else
        WR:Print("Unknown custom profile setting: " .. setting)
        WR:Print("Available settings:")
        
        for k, v in pairs(customProfile) do
            if k ~= "mod_factors" then
                WR:Print("  -", k, "=", tostring(v), "(", type(v), ")")
            end
        end
        
        WR:Print("Modification factors (use mod_factors.<name>):")
        if customProfile.mod_factors then
            for k, v in pairs(customProfile.mod_factors) do
                WR:Print("  -", "mod_factors." .. k, "=", tostring(v), "(", type(v), ")")
            end
        end
    end
}

-- Show configuration
function PlaystyleManager:ShowConfig()
    WR:Print("Playstyle Manager Configuration:")
    
    for k, v in pairs(config) do
        WR:Print(k .. ":", tostring(v))
    end
    
    WR:Print("")
    WR:Print("To change a setting, use: /wr playstyle config setting value")
    WR:Print("Example: /wr playstyle config enablePlaystyleProfiles true")
}

-- Create playstyle manager UI
function PlaystyleManager:CreatePlaystyleUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsPlaystyleUI", parent, "BackdropTemplate")
    frame:SetSize(600, 500)
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
    title:SetText("Playstyle Profiles")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create profile list
    local profileListFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    profileListFrame:SetSize(180, frame:GetHeight() - 80)
    profileListFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
    profileListFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    profileListFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    -- Create profile buttons
    local profileButtons = {}
    local buttonHeight = 30
    local yOffset = -10
    
    for _, profile in ipairs(self:GetAvailableProfiles()) do
        local button = CreateFrame("Button", nil, profileListFrame, "UIPanelButtonTemplate")
        button:SetSize(160, buttonHeight)
        button:SetPoint("TOPLEFT", profileListFrame, "TOPLEFT", 10, yOffset)
        button:SetText(profile.name)
        
        -- Highlight current profile
        if profile.name == currentProfile then
            button:SetEnabled(false)
        end
        
        -- Set up button behavior
        button:SetScript("OnClick", function()
            if PlaystyleManager:ApplyProfile(profile.name) then
                -- Update button states
                for _, btn in ipairs(profileButtons) do
                    btn:SetEnabled(btn:GetText() ~= profile.name)
                end
                
                -- Update details panel
                PlaystyleManager:UpdateDetailsPanel()
            end
        end)
        
        table.insert(profileButtons, button)
        yOffset = yOffset - (buttonHeight + 5)
    end
    
    -- Create details panel
    local detailsPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    detailsPanel:SetSize(frame:GetWidth() - 220, frame:GetHeight() - 80)
    detailsPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -60)
    detailsPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    detailsPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
    
    -- Store detailsPanel for updates
    frame.detailsPanel = detailsPanel
    
    -- Function to update details panel
    function PlaystyleManager:UpdateDetailsPanel()
        local panel = frame.detailsPanel
        
        -- Clear existing content
        for i = panel:GetNumChildren(), 1, -1 do
            local child = select(i, panel:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Get current profile
        local profileName, profile = self:GetCurrentProfile()
        
        -- Create scroll frame for details
        local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(panel:GetWidth() - 30, panel:GetHeight() - 30)
        scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Title
        local profileTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        profileTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        profileTitle:SetText(profileName .. " Profile")
        
        -- Description
        local descText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descText:SetPoint("TOPLEFT", profileTitle, "BOTTOMLEFT", 0, -10)
        descText:SetText("Description: " .. (profile.description or ""))
        
        local yOffset = -50
        
        -- Display profile settings
        for k, v in pairs(profile) do
            if k ~= "description" and k ~= "mod_factors" then
                local settingText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                settingText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
                settingText:SetText(k:gsub("_", " "):gsub("^%l", string.upper) .. ": " .. tostring(v))
                
                yOffset = yOffset - 20
            end
        end
        
        -- Display modification factors if available
        if profile.mod_factors then
            yOffset = yOffset - 10
            
            local factorsTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            factorsTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
            factorsTitle:SetText("Modification Factors:")
            
            yOffset = yOffset - 20
            
            for k, v in pairs(profile.mod_factors) do
                local factorText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                factorText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
                factorText:SetText(k:gsub("_", " "):gsub("^%l", string.upper) .. ": " .. tostring(v))
                
                yOffset = yOffset - 20
            end
        end
        
        -- Add edit controls for Custom profile
        if profileName == "Custom" then
            yOffset = yOffset - 20
            
            local editTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            editTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
            editTitle:SetText("Edit Custom Profile:")
            
            yOffset = yOffset - 30
            
            -- Add edit controls for common settings
            local settingOrder = {
                "rotation_complexity",
                "resource_strategy",
                "cooldown_usage",
                "defensives_usage"
            }
            
            for _, settingName in ipairs(settingOrder) do
                local settingValue = profile[settingName]
                
                if settingValue then
                    local settingLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    settingLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
                    settingLabel:SetText(settingName:gsub("_", " "):gsub("^%l", string.upper) .. ":")
                    
                    if settingName == "rotation_complexity" then
                        -- Slider for rotation complexity
                        local slider = CreateFrame("Slider", nil, scrollChild, "OptionsSliderTemplate")
                        slider:SetSize(200, 20)
                        slider:SetPoint("TOPLEFT", settingLabel, "TOPLEFT", 150, 0)
                        slider:SetMinMaxValues(1, 5)
                        slider:SetValue(tonumber(settingValue) or 3)
                        slider:SetValueStep(1)
                        slider:SetObeyStepOnDrag(true)
                        
                        slider.Low:SetText("Simple")
                        slider.High:SetText("Complex")
                        
                        slider:SetScript("OnValueChanged", function(self, value)
                            value = math.floor(value + 0.5) -- Round to nearest integer
                            customProfile.rotation_complexity = value
                            PlaystyleManager:UpdateCustomProfile(customProfile)
                            PlaystyleManager:UpdateDetailsPanel()
                        end)
                    elseif settingName == "resource_strategy" or 
                           settingName == "cooldown_usage" or 
                           settingName == "defensives_usage" then
                        -- Dropdown for strategy settings
                        local dropdown = CreateFrame("Frame", "WR_Dropdown_" .. settingName, scrollChild, "UIDropDownMenuTemplate")
                        dropdown:SetPoint("TOPLEFT", settingLabel, "TOPLEFT", 150, -5)
                        
                        local options = {
                            resource_strategy = {"conservative", "balanced", "aggressive"},
                            cooldown_usage = {"conservative", "optimal", "aggressive"},
                            defensives_usage = {"proactive", "balanced", "reactive"}
                        }
                        
                        UIDropDownMenu_SetWidth(dropdown, 120)
                        UIDropDownMenu_SetText(dropdown, settingValue)
                        
                        UIDropDownMenu_Initialize(dropdown, function(self, level)
                            local info = UIDropDownMenu_CreateInfo()
                            
                            for _, option in ipairs(options[settingName]) do
                                info.text = option:gsub("^%l", string.upper)
                                info.value = option
                                info.checked = (option == settingValue)
                                info.func = function()
                                    customProfile[settingName] = option
                                    PlaystyleManager:UpdateCustomProfile(customProfile)
                                    UIDropDownMenu_SetText(dropdown, option)
                                    PlaystyleManager:UpdateDetailsPanel()
                                end
                                
                                UIDropDownMenu_AddButton(info, level)
                            end
                        end)
                    end
                    
                    yOffset = yOffset - 40
                }
            end
            
            -- Add reset button for custom profile
            local resetButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            resetButton:SetSize(120, 24)
            resetButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
            resetButton:SetText("Reset Custom")
            resetButton:SetScript("OnClick", function()
                PlaystyleManager:ResetCustomProfile()
                PlaystyleManager:UpdateDetailsPanel()
            end)
            
            yOffset = yOffset - 40
        end
        
        -- Set scrollChild height
        scrollChild:SetHeight(math.abs(yOffset) + 20)
    end
    
    -- Initialize details panel
    self:UpdateDetailsPanel()
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Class-specific profile additions

-- MAGE profiles
function PlaystyleManager:AddProfiles_MAGE3()
    -- Frost Mage specific profiles
    presetProfiles["CleaveAoE"] = {
        description = "Frost Mage build focused on cleave and AoE damage",
        ability_count = "standard",
        prioritize = "aoe",
        cooldown_usage = "optimal",
        defensives_usage = "reactive",
        movement_style = "standard",
        rotation_complexity = 3,
        resource_strategy = "balanced",
        mod_factors = {
            ability_pruning = 0.0,
            consistency_weight = 1.0,
            cooldown_threshold = 0.6,
            defensive_threshold = 0.5,
            aoe_priority = 1.5,  -- Prioritize AoE abilities more
            single_target_priority = 0.7 -- Deprioritize single-target abilities
        }
    }
    
    presetProfiles["GlacialSpike"] = {
        description = "Frost Mage build focused on Glacial Spike bursts",
        ability_count = "full",
        prioritize = "burst",
        cooldown_usage = "aggressive",
        defensives_usage = "reactive",
        movement_style = "advanced",
        rotation_complexity = 4,
        resource_strategy = "conservative",
        mod_factors = {
            ability_pruning = -0.1,
            consistency_weight = 0.8,
            cooldown_threshold = 0.5,
            defensive_threshold = 0.4,
            burst_priority = 1.5,  -- Prioritize burst abilities
            glacial_spike_priority = 2.0 -- Heavy priority on Glacial Spike setup
        }
    }
}

function PlaystyleManager:AddProfiles_MAGE2()
    -- Fire Mage specific profiles
    presetProfiles["Combustion"] = {
        description = "Fire Mage build focused on maximizing Combustion windows",
        ability_count = "standard",
        prioritize = "burst",
        cooldown_usage = "optimal",
        defensives_usage = "reactive",
        movement_style = "advanced",
        rotation_complexity = 4,
        resource_strategy = "balanced",
        mod_factors = {
            ability_pruning = -0.1,
            consistency_weight = 0.7,
            cooldown_threshold = 0.5,
            defensive_threshold = 0.4,
            combustion_priority = 2.0 -- Heavy focus on Combustion setup and execution
        }
    }
}

-- WARRIOR profiles
function PlaystyleManager:AddProfiles_WARRIOR1()
    -- Arms Warrior specific profiles
    presetProfiles["Execute"] = {
        description = "Arms Warrior build focused on maximizing Execute phase damage",
        ability_count = "standard",
        prioritize = "execute",
        cooldown_usage = "optimal",
        defensives_usage = "reactive",
        movement_style = "standard",
        rotation_complexity = 3,
        resource_strategy = "aggressive",
        mod_factors = {
            ability_pruning = 0.0,
            consistency_weight = 0.9,
            cooldown_threshold = 0.6,
            defensive_threshold = 0.5,
            execute_priority = 2.0 -- Heavy focus on Execute phase performance
        }
    }
}

function PlaystyleManager:AddProfiles_WARRIOR2()
    -- Fury Warrior specific profiles
    presetProfiles["EnragedCleave"] = {
        description = "Fury Warrior build focused on maintaining Enrage and cleaving",
        ability_count = "standard",
        prioritize = "balanced",
        cooldown_usage = "aggressive",
        defensives_usage = "reactive",
        movement_style = "standard",
        rotation_complexity = 3,
        resource_strategy = "aggressive",
        mod_factors = {
            ability_pruning = 0.0,
            consistency_weight = 1.0,
            cooldown_threshold = 0.5,
            defensive_threshold = 0.4,
            enrage_uptime_priority = 1.8 -- Heavy focus on maintaining Enrage uptime
        }
    }
}

-- Add more class-specific profile additions here following the same pattern

-- Initialize the module
PlaystyleManager:Initialize()

return PlaystyleManager