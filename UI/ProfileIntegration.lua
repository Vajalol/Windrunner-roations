local addonName, WR = ...

-- ProfileIntegration module for saving/loading UI preferences as part of profiles
local ProfileIntegration = {}
WR.UI = WR.UI or {}
WR.UI.ProfileIntegration = ProfileIntegration

-- UI elements that need profile integration
local UI_PROFILE_ELEMENTS = {
    "EnhancedUI",
    "ClassHUD",
    "ClassTheme"
}

-- Initialize the module
function ProfileIntegration:Initialize()
    -- Register with profile manager if available
    if WR.ProfileManager then
        WR.ProfileManager:RegisterProfileDataHandler("UI", self.SaveUISettings, self.LoadUISettings)
        WR:Debug("ProfileIntegration module initialized and registered with ProfileManager")
    else
        WR:Debug("ProfileIntegration module initialized but no ProfileManager available")
    end
end

-- Save UI settings to a profile
function ProfileIntegration:SaveUISettings(profile)
    if not profile then return end
    
    -- Initialize UI section if it doesn't exist
    profile.UI = profile.UI or {}
    
    -- Save Enhanced UI settings
    if WR.UI.Enhanced then
        profile.UI.Enhanced = profile.UI.Enhanced or {}
        
        -- Save position and scale
        if WR.UI.Enhanced.mainContainer then
            local point, relativeTo, relativePoint, x, y = WR.UI.Enhanced.mainContainer:GetPoint()
            profile.UI.Enhanced.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y
            }
            profile.UI.Enhanced.scale = WR.UI.Enhanced.mainContainer:GetScale()
        end
        
        -- Save visibility state
        profile.UI.Enhanced.visible = WR.UI.Enhanced.mainContainer and WR.UI.Enhanced.mainContainer:IsShown()
        
        -- Save other settings
        profile.UI.Enhanced.showCastBar = WR.Config:Get("UI", "showCastBar")
        profile.UI.Enhanced.showQueuedSpells = WR.Config:Get("UI", "showQueuedSpells")
        profile.UI.Enhanced.showKeybinds = WR.Config:Get("UI", "showKeybinds")
        profile.UI.Enhanced.showCooldowns = WR.Config:Get("UI", "showCooldowns")
    end
    
    -- Save Class HUD settings
    if WR.UI.ClassHUD then
        profile.UI.ClassHUD = profile.UI.ClassHUD or {}
        
        -- Save position and scale
        if WR.UI.ClassHUD.mainFrame then
            local point, relativeTo, relativePoint, x, y = WR.UI.ClassHUD.mainFrame:GetPoint()
            profile.UI.ClassHUD.position = {
                point = point,
                relativePoint = relativePoint,
                x = x,
                y = y
            }
            profile.UI.ClassHUD.scale = WR.UI.ClassHUD.mainFrame:GetScale()
        end
        
        -- Save visibility state
        profile.UI.ClassHUD.visible = WR.UI.ClassHUD.mainFrame and WR.UI.ClassHUD.mainFrame:IsShown()
        
        -- Save other settings
        profile.UI.ClassHUD.showAuras = WR.Config:Get("UI", "showAuras")
        profile.UI.ClassHUD.showProcs = WR.Config:Get("UI", "showProcs")
        profile.UI.ClassHUD.showCooldowns = WR.Config:Get("UI", "showHUDCooldowns")
        profile.UI.ClassHUD.showResources = WR.Config:Get("UI", "showResources")
    end
    
    -- Save Class Theme settings
    if WR.UI.ClassTheme then
        profile.UI.ClassTheme = profile.UI.ClassTheme or {}
        
        profile.UI.ClassTheme.theme = WR.Config:Get("UI", "theme")
        profile.UI.ClassTheme.themeIntensity = WR.Config:Get("UI", "themeIntensity")
    end
    
    -- Save Responsive Layout settings
    if WR.UI.ResponsiveLayout then
        profile.UI.ResponsiveLayout = profile.UI.ResponsiveLayout or {}
        
        -- Save any custom layout settings
        profile.UI.ResponsiveLayout.useResponsiveLayout = WR.Config:Get("UI", "useResponsiveLayout")
    end
    
    -- Save Animation System settings
    if WR.UI.AnimationSystem then
        profile.UI.AnimationSystem = profile.UI.AnimationSystem or {}
        
        -- Save animation settings
        profile.UI.AnimationSystem.enableAnimations = WR.Config:Get("UI", "enableAnimations")
        profile.UI.AnimationSystem.animationIntensity = WR.Config:Get("UI", "animationIntensity")
    end
    
    WR:Debug("UI settings saved to profile")
    return profile
end

-- Load UI settings from a profile
function ProfileIntegration:LoadUISettings(profile)
    if not profile or not profile.UI then return end
    
    -- Load Enhanced UI settings
    if profile.UI.Enhanced and WR.UI.Enhanced then
        -- Load position and scale
        if profile.UI.Enhanced.position and WR.UI.Enhanced.mainContainer then
            WR.UI.Enhanced.mainContainer:ClearAllPoints()
            WR.UI.Enhanced.mainContainer:SetPoint(
                profile.UI.Enhanced.position.point,
                UIParent,
                profile.UI.Enhanced.position.relativePoint,
                profile.UI.Enhanced.position.x,
                profile.UI.Enhanced.position.y
            )
            
            if profile.UI.Enhanced.scale then
                WR.UI.Enhanced.mainContainer:SetScale(profile.UI.Enhanced.scale)
            end
        end
        
        -- Load visibility state
        if profile.UI.Enhanced.visible ~= nil then
            if profile.UI.Enhanced.visible then
                if WR.UI.Enhanced.Show then
                    WR.UI.Enhanced:Show()
                elseif WR.UI.Enhanced.mainContainer then
                    WR.UI.Enhanced.mainContainer:Show()
                end
            else
                if WR.UI.Enhanced.Hide then
                    WR.UI.Enhanced:Hide()
                elseif WR.UI.Enhanced.mainContainer then
                    WR.UI.Enhanced.mainContainer:Hide()
                end
            end
        end
        
        -- Load other settings
        if profile.UI.Enhanced.showCastBar ~= nil then
            WR.Config:Set("UI", profile.UI.Enhanced.showCastBar, "showCastBar")
        end
        
        if profile.UI.Enhanced.showQueuedSpells ~= nil then
            WR.Config:Set("UI", profile.UI.Enhanced.showQueuedSpells, "showQueuedSpells")
        end
        
        if profile.UI.Enhanced.showKeybinds ~= nil then
            WR.Config:Set("UI", profile.UI.Enhanced.showKeybinds, "showKeybinds")
        end
        
        if profile.UI.Enhanced.showCooldowns ~= nil then
            WR.Config:Set("UI", profile.UI.Enhanced.showCooldowns, "showCooldowns")
        end
        
        -- Apply settings if refresh method exists
        if WR.UI.Enhanced.RefreshSettings then
            WR.UI.Enhanced:RefreshSettings()
        end
    end
    
    -- Load Class HUD settings
    if profile.UI.ClassHUD and WR.UI.ClassHUD then
        -- Load position and scale
        if profile.UI.ClassHUD.position and WR.UI.ClassHUD.mainFrame then
            WR.UI.ClassHUD.mainFrame:ClearAllPoints()
            WR.UI.ClassHUD.mainFrame:SetPoint(
                profile.UI.ClassHUD.position.point,
                UIParent,
                profile.UI.ClassHUD.position.relativePoint,
                profile.UI.ClassHUD.position.x,
                profile.UI.ClassHUD.position.y
            )
            
            if profile.UI.ClassHUD.scale then
                WR.UI.ClassHUD.mainFrame:SetScale(profile.UI.ClassHUD.scale)
            end
        end
        
        -- Load visibility state
        if profile.UI.ClassHUD.visible ~= nil then
            if profile.UI.ClassHUD.visible then
                if WR.UI.ClassHUD.Show then
                    WR.UI.ClassHUD:Show()
                elseif WR.UI.ClassHUD.mainFrame then
                    WR.UI.ClassHUD.mainFrame:Show()
                end
            else
                if WR.UI.ClassHUD.Hide then
                    WR.UI.ClassHUD:Hide()
                elseif WR.UI.ClassHUD.mainFrame then
                    WR.UI.ClassHUD.mainFrame:Hide()
                end
            end
        end
        
        -- Load other settings
        if profile.UI.ClassHUD.showAuras ~= nil then
            WR.Config:Set("UI", profile.UI.ClassHUD.showAuras, "showAuras")
        end
        
        if profile.UI.ClassHUD.showProcs ~= nil then
            WR.Config:Set("UI", profile.UI.ClassHUD.showProcs, "showProcs")
        end
        
        if profile.UI.ClassHUD.showCooldowns ~= nil then
            WR.Config:Set("UI", profile.UI.ClassHUD.showHUDCooldowns, "showHUDCooldowns")
        end
        
        if profile.UI.ClassHUD.showResources ~= nil then
            WR.Config:Set("UI", profile.UI.ClassHUD.showResources, "showResources")
        end
        
        -- Apply settings if refresh method exists
        if WR.UI.ClassHUD.RefreshSettings then
            WR.UI.ClassHUD:RefreshSettings()
        end
    end
    
    -- Load Class Theme settings
    if profile.UI.ClassTheme and WR.UI.ClassTheme then
        if profile.UI.ClassTheme.theme then
            if profile.UI.ClassTheme.themeIntensity then
                WR.UI.ClassTheme:SetTheme(profile.UI.ClassTheme.theme, profile.UI.ClassTheme.themeIntensity)
            else
                WR.UI.ClassTheme:SetTheme(profile.UI.ClassTheme.theme)
            end
        end
    end
    
    -- Load Responsive Layout settings
    if profile.UI.ResponsiveLayout and WR.UI.ResponsiveLayout then
        if profile.UI.ResponsiveLayout.useResponsiveLayout ~= nil then
            WR.Config:Set("UI", profile.UI.ResponsiveLayout.useResponsiveLayout, "useResponsiveLayout")
            
            -- Apply settings
            if profile.UI.ResponsiveLayout.useResponsiveLayout then
                WR.UI.ResponsiveLayout:ApplyResponsiveLayouts()
            end
        end
    end
    
    -- Load Animation System settings
    if profile.UI.AnimationSystem and WR.UI.AnimationSystem then
        if profile.UI.AnimationSystem.enableAnimations ~= nil then
            WR.Config:Set("UI", profile.UI.AnimationSystem.enableAnimations, "enableAnimations")
        end
        
        if profile.UI.AnimationSystem.animationIntensity ~= nil then
            WR.Config:Set("UI", profile.UI.AnimationSystem.animationIntensity, "animationIntensity")
        end
    end
    
    WR:Debug("UI settings loaded from profile")
end

-- Create a UI settings tab for the profile UI
function ProfileIntegration:CreateProfileUITab(parent)
    if not parent then return end
    
    -- Create the settings container
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(parent:GetWidth() - 40, parent:GetHeight() - 40)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -20)
    
    -- Create a title
    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    title:SetText("UI Settings")
    
    -- Create checkboxes for UI element saving
    local checkboxes = {}
    local checkboxY = -30
    
    for i, element in ipairs(UI_PROFILE_ELEMENTS) do
        local checkbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, checkboxY - (i-1) * 25)
        checkbox:SetChecked(true)
        checkbox.element = element
        
        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText("Save " .. element .. " settings")
        
        checkboxes[element] = checkbox
    end
    
    -- Create description text
    local description = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description:SetPoint("TOPLEFT", checkboxes[UI_PROFILE_ELEMENTS[#UI_PROFILE_ELEMENTS]], "BOTTOMLEFT", 0, -15)
    description:SetWidth(container:GetWidth())
    description:SetJustifyH("LEFT")
    description:SetText("Select which UI elements to include when saving or loading profiles. Any unchecked elements will keep their current settings when a profile is loaded.")
    
    -- Add a warning about cross-class profiles
    local warning = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warning:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -15)
    warning:SetWidth(container:GetWidth())
    warning:SetJustifyH("LEFT")
    warning:SetTextColor(1, 0.5, 0)
    warning:SetText("Note: Loading UI settings from a profile created for a different class may result in suboptimal UI layouts for certain class-specific elements.")
    
    -- Save function
    container.GetSettings = function()
        local settings = {}
        
        for element, checkbox in pairs(checkboxes) do
            settings[element] = checkbox:GetChecked()
        end
        
        return settings
    end
    
    -- Load function
    container.SetSettings = function(settings)
        if not settings then return end
        
        for element, value in pairs(settings) do
            if checkboxes[element] then
                checkboxes[element]:SetChecked(value)
            end
        end
    end
    
    -- Hide by default
    container:Hide()
    
    return container
end

-- Add profile import/export validation for UI settings
function ProfileIntegration:ValidateProfileImport(profileData)
    if not profileData or not profileData.UI then return true end
    
    -- Add validation logic here if needed
    -- Return true if profile is valid, false otherwise
    
    -- Example validation:
    if profileData.UI.Enhanced and type(profileData.UI.Enhanced) ~= "table" then
        return false, "Invalid Enhanced UI settings in profile"
    end
    
    if profileData.UI.ClassHUD and type(profileData.UI.ClassHUD) ~= "table" then
        return false, "Invalid Class HUD settings in profile"
    end
    
    if profileData.UI.ClassTheme then
        if profileData.UI.ClassTheme.theme and type(profileData.UI.ClassTheme.theme) ~= "string" then
            return false, "Invalid theme setting in profile"
        end
        
        if profileData.UI.ClassTheme.themeIntensity and (type(profileData.UI.ClassTheme.themeIntensity) ~= "number" 
                or profileData.UI.ClassTheme.themeIntensity < 0 or profileData.UI.ClassTheme.themeIntensity > 1) then
            return false, "Invalid theme intensity in profile"
        end
    end
    
    return true
end

-- Copy settings between profiles
function ProfileIntegration:CopySettings(sourceProfile, targetProfile, settings)
    if not sourceProfile or not sourceProfile.UI or not targetProfile then return targetProfile end
    
    targetProfile.UI = targetProfile.UI or {}
    
    -- Copy only selected UI elements
    for element, include in pairs(settings) do
        if include and sourceProfile.UI[element] then
            targetProfile.UI[element] = CopyTable(sourceProfile.UI[element])
        end
    end
    
    return targetProfile
end

-- Reset UI settings to defaults
function ProfileIntegration:ResetToDefaults()
    -- Reset Enhanced UI settings
    if WR.UI.Enhanced then
        WR.Config:Set("UI", true, "showCastBar")
        WR.Config:Set("UI", true, "showQueuedSpells")
        WR.Config:Set("UI", true, "showKeybinds")
        WR.Config:Set("UI", true, "showCooldowns")
        
        if WR.UI.Enhanced.mainContainer then
            WR.UI.Enhanced.mainContainer:ClearAllPoints()
            WR.UI.Enhanced.mainContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            WR.UI.Enhanced.mainContainer:SetScale(1.0)
        end
        
        if WR.UI.Enhanced.RefreshSettings then
            WR.UI.Enhanced:RefreshSettings()
        end
    end
    
    -- Reset Class HUD settings
    if WR.UI.ClassHUD then
        WR.Config:Set("UI", true, "showAuras")
        WR.Config:Set("UI", true, "showProcs")
        WR.Config:Set("UI", true, "showHUDCooldowns")
        WR.Config:Set("UI", true, "showResources")
        
        if WR.UI.ClassHUD.mainFrame then
            WR.UI.ClassHUD.mainFrame:ClearAllPoints()
            WR.UI.ClassHUD.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
            WR.UI.ClassHUD.mainFrame:SetScale(1.0)
        end
        
        if WR.UI.ClassHUD.RefreshSettings then
            WR.UI.ClassHUD:RefreshSettings()
        end
    end
    
    -- Reset Class Theme settings
    if WR.UI.ClassTheme then
        WR.UI.ClassTheme:SetTheme("dark", 0.8)
    end
    
    -- Reset Responsive Layout settings
    if WR.UI.ResponsiveLayout then
        WR.Config:Set("UI", true, "useResponsiveLayout")
        WR.UI.ResponsiveLayout:ApplyResponsiveLayouts()
    end
    
    -- Reset Animation System settings
    if WR.UI.AnimationSystem then
        WR.Config:Set("UI", true, "enableAnimations")
        WR.Config:Set("UI", 0.7, "animationIntensity")
    end
    
    WR:Debug("UI settings reset to defaults")
end

-- Initialize the module
ProfileIntegration:Initialize()

return ProfileIntegration