------------------------------------------
-- WindrunnerRotations - Profile Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local ProfileManager = {}
WR.ProfileManager = ProfileManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Data storage
local currentProfile = nil
local profiles = {}
local DEFAULT_PROFILE_NAME = "Default"
local PROFILE_VERSION = 1
local COMPRESSION_ENABLED = true
local PROFILE_DB_VERSION = 1
local profileChangeListeners = {}
local exportFrame = nil
local importFrame = nil
local profileListFrame = nil
local playerInfo = {
    class = nil,
    spec = nil
}

-- Initialize the Profile Manager
function ProfileManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Initialize player info
    self:UpdatePlayerInfo()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Load profiles from saved variables
    self:LoadProfiles()
    
    -- Create UI frames
    self:CreateUI()
    
    API.PrintDebug("Profile Manager initialized")
    return true
end

-- Register settings
function ProfileManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("ProfileManager", {
        generalSettings = {
            currentProfile = {
                displayName = "Current Profile",
                description = "The currently active profile",
                type = "text",
                default = DEFAULT_PROFILE_NAME
            },
            autoSwitchProfiles = {
                displayName = "Auto-Switch Profiles",
                description = "Automatically switch profiles based on spec",
                type = "toggle",
                default = true
            },
            defaultProfilesPerSpec = {
                displayName = "Default Profile Per Spec",
                description = "Set a default profile for each specialization",
                type = "array",
                default = {}
            }
        },
        sharingSettings = {
            includePersonalNotes = {
                displayName = "Include Personal Notes",
                description = "Include personal notes when sharing profiles",
                type = "toggle",
                default = true
            },
            compressProfiles = {
                displayName = "Compress Profiles",
                description = "Compress profiles when exporting to reduce string length",
                type = "toggle",
                default = true
            },
            includeSpecInfo = {
                displayName = "Include Spec Information",
                description = "Include class and spec information when sharing profiles",
                type = "toggle",
                default = true
            }
        },
        advancedSettings = {
            backupProfiles = {
                displayName = "Backup Profiles",
                description = "Create automatic backups of profiles when changed",
                type = "toggle",
                default = true
            },
            maxBackups = {
                displayName = "Maximum Backups",
                description = "Maximum number of backups to keep per profile",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 3
            },
            profileVersioning = {
                displayName = "Profile Versioning",
                description = "Enable versioning for profiles",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Register for events
function ProfileManager:RegisterEvents()
    -- Register for player specialization change
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for addon loaded event
    API.RegisterEvent("ADDON_LOADED", function(addon)
        if addon == addonName then
            self:OnAddonLoaded()
        end
    end)
    
    -- Register for player logout
    API.RegisterEvent("PLAYER_LOGOUT", function()
        self:SaveProfiles()
    end)
}

-- Update player info
function ProfileManager:UpdatePlayerInfo()
    -- Get player class
    local _, class = UnitClass("player")
    playerInfo.class = class
    
    -- Get player spec
    local specID = API.GetActiveSpecID()
    playerInfo.spec = specID
}

-- Load profiles from saved variables
function ProfileManager:LoadProfiles()
    -- This would load from SavedVariables in a real addon
    -- For implementation simplicity, we'll initialize with defaults
    
    -- Initialize default profiles for each class/spec
    self:InitializeDefaultProfiles()
    
    -- Set current profile based on settings
    local settings = ConfigRegistry:GetSettings("ProfileManager")
    currentProfile = settings.generalSettings.currentProfile
    
    -- If the current profile doesn't exist, create it
    if not profiles[currentProfile] then
        self:CreateProfile(currentProfile)
    end
}

-- Save profiles to saved variables
function ProfileManager:SaveProfiles()
    -- This would save to SavedVariables in a real addon
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("Saving profiles to database")
    
    -- Update current profile in settings
    local settings = ConfigRegistry:GetSettings("ProfileManager")
    settings.generalSettings.currentProfile = currentProfile
}

-- Initialize default profiles
function ProfileManager:InitializeDefaultProfiles()
    -- Create default profile
    self:CreateProfile(DEFAULT_PROFILE_NAME)
    
    -- Initialize each class with default profiles
    local classes = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
        "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
        "DRUID", "DEMONHUNTER", "EVOKER"
    }
    
    for _, class in ipairs(classes) do
        -- Create class-specific default profile
        local profileName = class .. " Default"
        self:CreateProfile(profileName, class)
    end
    
    -- Initialize specific class-spec profiles (just a few examples)
    self:CreateProfile("Fire Mage Mythic+", "MAGE", 2)
    self:CreateProfile("Frost Mage Raid", "MAGE", 3)
    self:CreateProfile("Affliction Warlock Mythic+", "WARLOCK", 1)
    self:CreateProfile("Affliction Warlock Raid", "WARLOCK", 1)
}

-- Create a new profile
function ProfileManager:CreateProfile(name, class, spec)
    -- Skip if profile already exists
    if profiles[name] then
        return false
    end
    
    -- Create new profile
    profiles[name] = {
        name = name,
        class = class,
        spec = spec,
        version = PROFILE_VERSION,
        created = time(),
        lastModified = time(),
        settings = {},
        notes = "",
        author = UnitName("player"),
        realm = GetRealmName(),
        backups = {}
    }
    
    -- Initialize settings with defaults
    if class and spec then
        -- Copy default settings for this class/spec
        profiles[name].settings = self:GetDefaultSettingsForClassSpec(class, spec)
    else
        -- Generic default settings
        profiles[name].settings = self:GetDefaultSettings()
    end
    
    API.PrintDebug("Created profile: " .. name)
    return true
end

-- Delete a profile
function ProfileManager:DeleteProfile(name)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return false
    end
    
    -- Skip if it's the current profile
    if name == currentProfile then
        API.PrintError("Cannot delete the current profile")
        return false
    end
    
    -- Delete the profile
    profiles[name] = nil
    
    API.PrintDebug("Deleted profile: " .. name)
    return true
end

-- Rename a profile
function ProfileManager:RenameProfile(oldName, newName)
    -- Skip if old profile doesn't exist
    if not profiles[oldName] then
        return false
    end
    
    -- Skip if new name already exists
    if profiles[newName] then
        API.PrintError("Profile with name '" .. newName .. "' already exists")
        return false
    end
    
    -- Copy the profile
    profiles[newName] = table.copy(profiles[oldName])
    profiles[newName].name = newName
    
    -- Update current profile if needed
    if oldName == currentProfile then
        currentProfile = newName
    end
    
    -- Delete old profile
    profiles[oldName] = nil
    
    API.PrintDebug("Renamed profile: " .. oldName .. " to " .. newName)
    return true
end

-- Copy a profile
function ProfileManager:CopyProfile(sourceName, destName)
    -- Skip if source profile doesn't exist
    if not profiles[sourceName] then
        return false
    end
    
    -- Skip if destination profile already exists
    if profiles[destName] then
        API.PrintError("Profile with name '" .. destName .. "' already exists")
        return false
    end
    
    -- Copy the profile
    profiles[destName] = table.copy(profiles[sourceName])
    profiles[destName].name = destName
    profiles[destName].created = time()
    profiles[destName].lastModified = time()
    
    API.PrintDebug("Copied profile: " .. sourceName .. " to " .. destName)
    return true
end

-- Reset a profile to defaults
function ProfileManager:ResetProfile(name)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return false
    end
    
    -- Backup current settings
    if profiles[name].settings then
        -- Create backup
        self:CreateProfileBackup(name)
    end
    
    -- Reset to defaults
    if profiles[name].class and profiles[name].spec then
        -- Reset to class/spec defaults
        profiles[name].settings = self:GetDefaultSettingsForClassSpec(profiles[name].class, profiles[name].spec)
    else
        -- Reset to generic defaults
        profiles[name].settings = self:GetDefaultSettings()
    end
    
    -- Update last modified
    profiles[name].lastModified = time()
    
    -- Notify listeners
    self:NotifyProfileChanged(name)
    
    API.PrintDebug("Reset profile: " .. name)
    return true
end

-- Create a backup of a profile
function ProfileManager:CreateProfileBackup(name)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return false
    end
    
    -- Skip if backups are disabled
    local settings = ConfigRegistry:GetSettings("ProfileManager")
    if not settings.advancedSettings.backupProfiles then
        return false
    end
    
    -- Create backup
    local backup = {
        timestamp = time(),
        settings = table.copy(profiles[name].settings)
    }
    
    -- Add to backups
    if not profiles[name].backups then
        profiles[name].backups = {}
    end
    
    table.insert(profiles[name].backups, backup)
    
    -- Trim backups if needed
    local maxBackups = settings.advancedSettings.maxBackups
    while #profiles[name].backups > maxBackups do
        table.remove(profiles[name].backups, 1)
    end
    
    API.PrintDebug("Created backup for profile: " .. name)
    return true
end

-- Restore a profile from backup
function ProfileManager:RestoreProfileBackup(name, index)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return false
    end
    
    -- Skip if backup doesn't exist
    if not profiles[name].backups or not profiles[name].backups[index] then
        return false
    end
    
    -- Create a backup of current settings first
    self:CreateProfileBackup(name)
    
    -- Restore from backup
    profiles[name].settings = table.copy(profiles[name].backups[index].settings)
    profiles[name].lastModified = time()
    
    -- Notify listeners
    self:NotifyProfileChanged(name)
    
    API.PrintDebug("Restored profile: " .. name .. " from backup " .. index)
    return true
end

-- Switch to a profile
function ProfileManager:SwitchProfile(name)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return false
    end
    
    -- Skip if it's already the current profile
    if name == currentProfile then
        return true
    end
    
    -- Switch profile
    currentProfile = name
    
    -- Apply settings from the profile
    self:ApplyProfileSettings(name)
    
    -- Notify listeners
    self:NotifyProfileChanged(name)
    
    API.PrintDebug("Switched to profile: " .. name)
    return true
}

-- Apply settings from a profile
function ProfileManager:ApplyProfileSettings(name)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return false
    end
    
    -- Apply settings
    -- This would apply all settings from the profile
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("Applying settings from profile: " .. name)
    
    -- This would iterate through all settings categories and apply them
    for category, settings in pairs(profiles[name].settings) do
        API.PrintDebug("Applying settings for category: " .. category)
        
        -- Apply settings to ConfigRegistry
        -- ConfigRegistry:ApplySettings(category, settings)
    end
    
    return true
}

-- Get default settings
function ProfileManager:GetDefaultSettings()
    -- This would return default settings for all categories
    -- For implementation simplicity, we'll return an empty table
    return {}
}

-- Get default settings for a class/spec
function ProfileManager:GetDefaultSettingsForClassSpec(class, spec)
    -- This would return default settings for the specified class/spec
    -- For implementation simplicity, we'll return an empty table
    return {}
}

-- Export a profile
function ProfileManager:ExportProfile(name)
    -- Skip if profile doesn't exist
    if not profiles[name] then
        return nil
    end
    
    -- Prepare export data
    local exportData = {
        name = profiles[name].name,
        version = PROFILE_VERSION,
        dbVersion = PROFILE_DB_VERSION,
        settings = profiles[name].settings,
        notes = profiles[name].notes,
        author = profiles[name].author,
        realm = profiles[name].realm,
        created = profiles[name].created
    }
    
    -- Include class/spec info if enabled
    local settings = ConfigRegistry:GetSettings("ProfileManager")
    if settings.sharingSettings.includeSpecInfo then
        exportData.class = profiles[name].class
        exportData.spec = profiles[name].spec
    end
    
    -- Include personal notes if enabled
    if not settings.sharingSettings.includePersonalNotes then
        exportData.notes = nil
    end
    
    -- Serialize the data
    local serialized = self:SerializeData(exportData)
    
    -- Compress if enabled
    if settings.sharingSettings.compressProfiles then
        serialized = self:CompressData(serialized)
    end
    
    -- Encode for sharing
    local encoded = self:EncodeForSharing(serialized)
    
    return encoded
}

-- Import a profile
function ProfileManager:ImportProfile(encoded)
    -- Decode the shared string
    local serialized = self:DecodeFromSharing(encoded)
    if not serialized then
        API.PrintError("Invalid profile string")
        return false
    end
    
    -- Decompress if needed
    if self:IsCompressedData(serialized) then
        serialized = self:DecompressData(serialized)
    end
    
    -- Deserialize the data
    local importData = self:DeserializeData(serialized)
    if not importData then
        API.PrintError("Failed to deserialize profile data")
        return false
    end
    
    -- Validate the imported data
    if not self:ValidateImportData(importData) then
        API.PrintError("Invalid profile data")
        return false
    end
    
    -- Check if profile already exists
    local profileName = importData.name
    local counter = 1
    
    while profiles[profileName] do
        profileName = importData.name .. " (" .. counter .. ")"
        counter = counter + 1
    end
    
    -- Create new profile
    profiles[profileName] = {
        name = profileName,
        class = importData.class,
        spec = importData.spec,
        version = importData.version or PROFILE_VERSION,
        created = time(),
        lastModified = time(),
        settings = importData.settings or {},
        notes = importData.notes or "",
        author = importData.author or "Unknown",
        realm = importData.realm or "Unknown",
        imported = true,
        importedFrom = {
            author = importData.author,
            realm = importData.realm,
            created = importData.created
        },
        backups = {}
    }
    
    API.PrintDebug("Imported profile: " .. profileName)
    return profileName
}

-- Validate import data
function ProfileManager:ValidateImportData(data)
    -- Check required fields
    if not data.name or not data.settings or not data.version then
        return false
    end
    
    -- Check version compatibility
    if data.dbVersion and data.dbVersion > PROFILE_DB_VERSION then
        return false
    end
    
    return true
}

-- Serialize data
function ProfileManager:SerializeData(data)
    -- In a real addon, this would use proper serialization
    -- For implementation simplicity, we'll just convert to JSON
    return JSON.stringify(data)
}

-- Deserialize data
function ProfileManager:DeserializeData(serialized)
    -- In a real addon, this would use proper deserialization
    -- For implementation simplicity, we'll just parse JSON
    return JSON.parse(serialized)
}

-- Compress data
function ProfileManager:CompressData(data)
    -- In a real addon, this would use proper compression
    -- For implementation simplicity, we'll just mark it as compressed
    return "COMPRESSED:" .. data
}

-- Decompress data
function ProfileManager:DecompressData(data)
    -- In a real addon, this would use proper decompression
    -- For implementation simplicity, we'll just remove the marker
    return string.sub(data, 12)
}

-- Check if data is compressed
function ProfileManager:IsCompressedData(data)
    -- Check if data starts with compression marker
    return string.sub(data, 1, 11) == "COMPRESSED:"
}

-- Encode for sharing
function ProfileManager:EncodeForSharing(data)
    -- In a real addon, this would use proper encoding (base64, etc)
    -- For implementation simplicity, we'll just add a prefix
    return "WR:" .. data
}

-- Decode from sharing
function ProfileManager:DecodeFromSharing(encoded)
    -- In a real addon, this would use proper decoding
    -- For implementation simplicity, we'll just remove the prefix
    
    -- Check if it's a valid WindrunnerRotations profile
    if string.sub(encoded, 1, 3) ~= "WR:" then
        return nil
    end
    
    return string.sub(encoded, 4)
}

-- Register profile change listener
function ProfileManager:RegisterProfileChangeListener(callback)
    table.insert(profileChangeListeners, callback)
}

-- Notify profile changed
function ProfileManager:NotifyProfileChanged(name)
    for _, callback in ipairs(profileChangeListeners) do
        callback(name)
    end
}

-- On specialization changed
function ProfileManager:OnSpecializationChanged()
    -- Update player info
    self:UpdatePlayerInfo()
    
    -- Check if we should auto-switch profiles
    local settings = ConfigRegistry:GetSettings("ProfileManager")
    if settings.generalSettings.autoSwitchProfiles then
        -- Get default profile for this spec
        local defaultProfiles = settings.generalSettings.defaultProfilesPerSpec
        local specKey = playerInfo.class .. "-" .. playerInfo.spec
        
        if defaultProfiles[specKey] and profiles[defaultProfiles[specKey]] then
            -- Switch to the default profile for this spec
            self:SwitchProfile(defaultProfiles[specKey])
        end
    end
}

-- On addon loaded
function ProfileManager:OnAddonLoaded()
    -- This would load profiles from saved variables
    -- For implementation simplicity, we'll just initialize with defaults
    self:LoadProfiles()
}

-- Create UI
function ProfileManager:CreateUI()
    -- Create export frame
    exportFrame = self:CreateExportFrame()
    exportFrame:Hide()
    
    -- Create import frame
    importFrame = self:CreateImportFrame()
    importFrame:Hide()
    
    -- Create profile list frame
    profileListFrame = self:CreateProfileListFrame()
    profileListFrame:Hide()
}

-- Create export frame
function ProfileManager:CreateExportFrame()
    -- Create a frame for exporting profiles
    local frame = CreateFrame("Frame", "WindrunnerProfileExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 300)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.4, 0.6, 0.9, 0.8)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Add title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Export Profile")
    
    -- Add profile dropdown
    local profileDropdown = CreateFrame("Frame", "WindrunnerProfileExportDropdown", frame, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOP", title, "BOTTOM", 0, -10)
    
    -- Add export box
    local exportBox = CreateFrame("EditBox", "WindrunnerProfileExportBox", frame, "InputBoxTemplate")
    exportBox:SetSize(460, 180)
    exportBox:SetPoint("TOP", profileDropdown, "BOTTOM", 0, -20)
    exportBox:SetAutoFocus(false)
    exportBox:SetMultiLine(true)
    exportBox:SetMaxLetters(9999999)
    exportBox:SetFontObject("GameFontHighlight")
    exportBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Add export button
    local exportButton = CreateFrame("Button", "WindrunnerProfileExportButton", frame, "UIPanelButtonTemplate")
    exportButton:SetSize(100, 25)
    exportButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    exportButton:SetText("Export")
    exportButton:SetScript("OnClick", function()
        -- Get selected profile
        local selectedProfile = UIDropDownMenu_GetSelectedValue(profileDropdown)
        
        -- Export profile
        local exportString = self:ExportProfile(selectedProfile)
        
        -- Set export box text
        exportBox:SetText(exportString)
        exportBox:HighlightText()
        exportBox:SetFocus()
    end)
    
    -- Add close button
    local closeButton = CreateFrame("Button", "WindrunnerProfileExportCloseButton", frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for name, _ in pairs(profiles) do
            info.text = name
            info.value = name
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(profileDropdown, self.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial value
    UIDropDownMenu_SetSelectedValue(profileDropdown, currentProfile)
    UIDropDownMenu_SetWidth(profileDropdown, 200)
    
    -- Store references
    frame.exportBox = exportBox
    frame.exportButton = exportButton
    frame.profileDropdown = profileDropdown
    
    return frame
}

-- Create import frame
function ProfileManager:CreateImportFrame()
    -- Create a frame for importing profiles
    local frame = CreateFrame("Frame", "WindrunnerProfileImportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 300)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.4, 0.6, 0.9, 0.8)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Add title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Import Profile")
    
    -- Add import box
    local importBox = CreateFrame("EditBox", "WindrunnerProfileImportBox", frame, "InputBoxTemplate")
    importBox:SetSize(460, 180)
    importBox:SetPoint("TOP", title, "BOTTOM", 0, -30)
    importBox:SetAutoFocus(false)
    importBox:SetMultiLine(true)
    importBox:SetMaxLetters(9999999)
    importBox:SetFontObject("GameFontHighlight")
    importBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Add import button
    local importButton = CreateFrame("Button", "WindrunnerProfileImportButton", frame, "UIPanelButtonTemplate")
    importButton:SetSize(100, 25)
    importButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        -- Get import string
        local importString = importBox:GetText()
        
        -- Import profile
        local profileName = self:ImportProfile(importString)
        
        if profileName then
            -- Show success message
            local resultText = frame.resultText
            resultText:SetText("Successfully imported profile: " .. profileName)
            resultText:SetTextColor(0, 1, 0, 1)
            
            -- Clear import box
            importBox:SetText("")
        else
            -- Show error message
            local resultText = frame.resultText
            resultText:SetText("Failed to import profile. Invalid profile string.")
            resultText:SetTextColor(1, 0, 0, 1)
        end
    end)
    
    -- Add close button
    local closeButton = CreateFrame("Button", "WindrunnerProfileImportCloseButton", frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Add result text
    local resultText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resultText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 40)
    resultText:SetText("")
    
    -- Store references
    frame.importBox = importBox
    frame.importButton = importButton
    frame.resultText = resultText
    
    return frame
}

-- Create profile list frame
function ProfileManager:CreateProfileListFrame()
    -- Create a frame for listing profiles
    local frame = CreateFrame("Frame", "WindrunnerProfileListFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        tile = true,
        tileSize = 16,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.4, 0.6, 0.9, 0.8)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Add title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Profiles")
    
    -- Add scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "WindrunnerProfileListScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
    
    -- Add content frame
    local contentFrame = CreateFrame("Frame", "WindrunnerProfileListContentFrame", scrollFrame)
    contentFrame:SetSize(scrollFrame:GetWidth(), 1000) -- Height will be set dynamically
    scrollFrame:SetScrollChild(contentFrame)
    
    -- Add buttons
    local newButton = CreateFrame("Button", "WindrunnerProfileNewButton", frame, "UIPanelButtonTemplate")
    newButton:SetSize(80, 25)
    newButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    newButton:SetText("New")
    newButton:SetScript("OnClick", function()
        -- Show new profile dialog
        self:ShowNewProfileDialog()
    end)
    
    local importButton = CreateFrame("Button", "WindrunnerProfileImportButton", frame, "UIPanelButtonTemplate")
    importButton:SetSize(80, 25)
    importButton:SetPoint("LEFT", newButton, "RIGHT", 5, 0)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        -- Show import frame
        importFrame:Show()
    end)
    
    local closeButton = CreateFrame("Button", "WindrunnerProfileListCloseButton", frame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 25)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Store references
    frame.scrollFrame = scrollFrame
    frame.contentFrame = contentFrame
    frame.newButton = newButton
    frame.importButton = importButton
    frame.profileButtons = {}
    
    -- Add refresh function
    frame.Refresh = function()
        self:RefreshProfileList(frame)
    end
    
    return frame
}

-- Show export frame
function ProfileManager:ShowExportFrame(profileName)
    -- Set selected profile
    UIDropDownMenu_SetSelectedValue(exportFrame.profileDropdown, profileName or currentProfile)
    
    -- Set export box text
    local exportString = self:ExportProfile(profileName or currentProfile)
    exportFrame.exportBox:SetText(exportString)
    exportFrame.exportBox:HighlightText()
    
    -- Show frame
    exportFrame:Show()
    exportFrame.exportBox:SetFocus()
}

-- Show import frame
function ProfileManager:ShowImportFrame()
    -- Clear import box
    importFrame.importBox:SetText("")
    importFrame.resultText:SetText("")
    
    -- Show frame
    importFrame:Show()
    importFrame.importBox:SetFocus()
}

-- Show profile list
function ProfileManager:ShowProfileList()
    -- Refresh profile list
    profileListFrame.Refresh()
    
    -- Show frame
    profileListFrame:Show()
}

-- Refresh profile list
function ProfileManager:RefreshProfileList(frame)
    -- Clear existing buttons
    for _, button in ipairs(frame.profileButtons) do
        button:Hide()
    end
    frame.profileButtons = {}
    
    -- Add profile buttons
    local yOffset = 0
    local buttonHeight = 30
    
    for name, profile in pairs(profiles) do
        -- Create button
        local button = CreateFrame("Button", nil, frame.contentFrame, "BackdropTemplate")
        button:SetSize(frame.contentFrame:GetWidth() - 20, buttonHeight)
        button:SetPoint("TOPLEFT", frame.contentFrame, "TOPLEFT", 10, -yOffset)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = true,
            tileSize = 16,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        
        -- Set button color
        if name == currentProfile then
            -- Current profile
            button:SetBackdropColor(0.2, 0.4, 0.6, 0.8)
            button:SetBackdropBorderColor(0.4, 0.6, 0.9, 0.8)
        else
            -- Other profile
            button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            button:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        end
        
        -- Add highlight
        button:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        
        -- Add profile name
        local nameText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", 10, 0)
        nameText:SetText(name)
        
        -- Add class/spec info if available
        if profile.class and profile.spec then
            local classSpecText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            classSpecText:SetPoint("RIGHT", -100, 0)
            
            -- Get class/spec names
            local className = profile.class
            local specName = "Spec " .. profile.spec
            
            classSpecText:SetText(className .. " - " .. specName)
        end
        
        -- Add buttons
        local switchButton = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
        switchButton:SetSize(60, 20)
        switchButton:SetPoint("RIGHT", button, "RIGHT", -10, 0)
        switchButton:SetText("Switch")
        switchButton:SetScript("OnClick", function()
            -- Switch to this profile
            self:SwitchProfile(name)
            
            -- Refresh the list
            frame.Refresh()
        end)
        
        local exportButton = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
        exportButton:SetSize(60, 20)
        exportButton:SetPoint("RIGHT", switchButton, "LEFT", -5, 0)
        exportButton:SetText("Export")
        exportButton:SetScript("OnClick", function()
            -- Show export frame for this profile
            self:ShowExportFrame(name)
        end)
        
        -- Set click handler
        button:SetScript("OnClick", function()
            -- Open profile options
            self:ShowProfileOptions(name)
        end)
        
        -- Disable switch button if it's the current profile
        if name == currentProfile then
            switchButton:Disable()
        end
        
        -- Add to buttons list
        table.insert(frame.profileButtons, button)
        
        -- Update offset
        yOffset = yOffset + buttonHeight + 5
    end
    
    -- Update content frame height
    frame.contentFrame:SetHeight(yOffset)
}

-- Show profile options
function ProfileManager:ShowProfileOptions(name)
    -- This would show a dialog with profile options
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("Showing options for profile: " .. name)
}

-- Show new profile dialog
function ProfileManager:ShowNewProfileDialog()
    -- This would show a dialog for creating a new profile
    -- For implementation simplicity, we'll just create a new profile
    
    -- Generate a unique name
    local name = "New Profile"
    local counter = 1
    
    while profiles[name] do
        name = "New Profile " .. counter
        counter = counter + 1
    end
    
    -- Create the profile
    self:CreateProfile(name)
    
    -- Refresh the profile list
    profileListFrame.Refresh()
}

-- Open profile manager
function ProfileManager:OpenProfileManager()
    self:ShowProfileList()
}

-- Get active profile name
function ProfileManager:GetActiveProfileName()
    return currentProfile
}

-- Get active profile
function ProfileManager:GetActiveProfile()
    return profiles[currentProfile]
}

-- Get profile by name
function ProfileManager:GetProfile(name)
    return profiles[name]
}

-- Get all profiles
function ProfileManager:GetAllProfiles()
    return profiles
}

-- Get profiles for class/spec
function ProfileManager:GetProfilesForClassSpec(class, spec)
    local result = {}
    
    for name, profile in pairs(profiles) do
        if profile.class == class and profile.spec == spec then
            result[name] = profile
        end
    end
    
    return result
}

-- Set default profile for spec
function ProfileManager:SetDefaultProfileForSpec(class, spec, profileName)
    -- Skip if profile doesn't exist
    if not profiles[profileName] then
        return false
    end
    
    -- Update settings
    local settings = ConfigRegistry:GetSettings("ProfileManager")
    local specKey = class .. "-" .. spec
    
    settings.generalSettings.defaultProfilesPerSpec[specKey] = profileName
    
    API.PrintDebug("Set default profile for " .. class .. "-" .. spec .. " to " .. profileName)
    return true
}

-- Return the module
return ProfileManager