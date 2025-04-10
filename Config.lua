local addonName, WR = ...

-- Config management
local Config = {}
WR.Config = Config

-- Default settings
local defaults = {
    enabled = true,
    enableAutoTargeting = true,
    enableInterrupts = true,
    enableDefensives = true,
    enableCooldowns = false,
    enableAOE = false,
    enableDungeonAwareness = true,
    rotationSpeed = 100, -- milliseconds
    UI = {
        scale = 1.0,
        locked = false,
        position = { point = "CENTER", x = 0, y = 0 },
    },
    keybinds = {
        toggle = nil,
        cooldowns = nil,
        aoe = nil,
    }
}

-- Initialize config with saved variables
function Config:Initialize()
    -- Create the saved variables if they don't exist
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = CopyTable(defaults)
    end
    
    if not WindrunnerRotationsCharDB then
        WindrunnerRotationsCharDB = {
            currentProfile = "Default",
            classProfiles = {},
        }
    end
    
    -- Ensure all default values exist (in case of addon update with new settings)
    for k, v in pairs(defaults) do
        if WindrunnerRotationsDB[k] == nil then
            WindrunnerRotationsDB[k] = v
        end
    end
    
    self.db = WindrunnerRotationsDB
    self.charDB = WindrunnerRotationsCharDB
end

-- Get a config value
function Config:Get(key, subkey)
    if not self.db then
        self:Initialize()
    end
    
    if subkey then
        if self.db[key] then
            return self.db[key][subkey]
        end
        return nil
    end
    
    return self.db[key]
end

-- Set a config value
function Config:Set(key, value, subkey)
    if not self.db then
        self:Initialize()
    end
    
    if subkey then
        if not self.db[key] then
            self.db[key] = {}
        end
        self.db[key][subkey] = value
    else
        self.db[key] = value
    end
end

-- Get a character-specific value
function Config:GetChar(key, subkey)
    if not self.charDB then
        self:Initialize()
    end
    
    if subkey then
        if self.charDB[key] then
            return self.charDB[key][subkey]
        end
        return nil
    end
    
    return self.charDB[key]
end

-- Set a character-specific value
function Config:SetChar(key, value, subkey)
    if not self.charDB then
        self:Initialize()
    end
    
    if subkey then
        if not self.charDB[key] then
            self.charDB[key] = {}
        end
        self.charDB[key][subkey] = value
    else
        self.charDB[key] = value
    end
end

-- Get the current profile for the player's class/spec
function Config:GetCurrentProfile()
    local profileName = self:GetChar("currentProfile") or "Default"
    return profileName
end

-- Set the current profile for the player's class/spec
function Config:SetCurrentProfile(profileName)
    self:SetChar("currentProfile", profileName)
end

-- Get class profile settings
function Config:GetClassProfile(profileName)
    profileName = profileName or self:GetCurrentProfile()
    
    local classProfiles = self:GetChar("classProfiles") or {}
    local className = WR.class
    local specID = WR.currentSpec
    
    if not classProfiles[className] then
        classProfiles[className] = {}
    end
    
    if not classProfiles[className][specID] then
        classProfiles[className][specID] = {}
    end
    
    if not classProfiles[className][specID][profileName] then
        classProfiles[className][specID][profileName] = {
            name = profileName,
            priority = {},
            cooldowns = {},
            defensives = {},
            utility = {},
            talents = {},
        }
    end
    
    return classProfiles[className][specID][profileName]
end

-- Save class profile settings
function Config:SaveClassProfile(profileData, profileName)
    profileName = profileName or self:GetCurrentProfile()
    
    local classProfiles = self:GetChar("classProfiles") or {}
    local className = WR.class
    local specID = WR.currentSpec
    
    if not classProfiles[className] then
        classProfiles[className] = {}
    end
    
    if not classProfiles[className][specID] then
        classProfiles[className][specID] = {}
    end
    
    classProfiles[className][specID][profileName] = profileData
    self:SetChar("classProfiles", classProfiles)
end

-- Get all profiles for current class/spec
function Config:GetAllProfiles()
    local classProfiles = self:GetChar("classProfiles") or {}
    local className = WR.class
    local specID = WR.currentSpec
    
    if not classProfiles[className] or not classProfiles[className][specID] then
        return {}
    end
    
    return classProfiles[className][specID]
end

-- Create a new profile
function Config:CreateProfile(profileName)
    if not profileName or profileName == "" then
        profileName = "Profile " .. date("%Y%m%d%H%M%S")
    end
    
    local currentProfile = self:GetClassProfile(self:GetCurrentProfile())
    local newProfile = CopyTable(currentProfile)
    newProfile.name = profileName
    
    self:SaveClassProfile(newProfile, profileName)
    self:SetCurrentProfile(profileName)
    
    return profileName
end

-- Delete a profile
function Config:DeleteProfile(profileName)
    local classProfiles = self:GetChar("classProfiles") or {}
    local className = WR.class
    local specID = WR.currentSpec
    
    if not classProfiles[className] or 
       not classProfiles[className][specID] or 
       not classProfiles[className][specID][profileName] then
        return false
    end
    
    classProfiles[className][specID][profileName] = nil
    self:SetChar("classProfiles", classProfiles)
    
    -- If we deleted the current profile, switch to Default
    if self:GetCurrentProfile() == profileName then
        self:SetCurrentProfile("Default")
    end
    
    return true
end

-- Apply a profile settings to rotation
function Config:ApplyProfile(profileName)
    profileName = profileName or self:GetCurrentProfile()
    local profile = self:GetClassProfile(profileName)
    
    -- Set the profile as current
    self:SetCurrentProfile(profileName)
    
    -- Apply the profile settings to the current rotation
    if WR.Classes[WR.class] and WR.Classes[WR.class].ApplyProfile then
        WR.Classes[WR.class]:ApplyProfile(profile)
    end
    
    return true
end

-- Export profile to string (for sharing)
function Config:ExportProfile(profileName)
    profileName = profileName or self:GetCurrentProfile()
    local profile = self:GetClassProfile(profileName)
    
    if not profile then return nil end
    
    -- Convert to compressed string
    local serialized = WR.API.Serialize(profile)
    local compressed = WR.API.Compress(serialized)
    local encoded = WR.API.Encode(compressed)
    
    return encoded
end

-- Import profile from string
function Config:ImportProfile(encodedString, profileName)
    if not encodedString or encodedString == "" then
        return false, "Empty profile string"
    end
    
    local success, result = pcall(function()
        local compressed = WR.API.Decode(encodedString)
        local serialized = WR.API.Decompress(compressed)
        local profile = WR.API.Deserialize(serialized)
        
        if not profile or type(profile) ~= "table" then
            return false, "Invalid profile data"
        end
        
        -- Save with new name if provided
        if profileName and profileName ~= "" then
            profile.name = profileName
        end
        
        self:SaveClassProfile(profile, profile.name)
        return true, profile.name
    end)
    
    if not success then
        return false, "Failed to import profile: " .. result
    end
    
    return result
end

-- Register for events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonLoaded)
    if event == "ADDON_LOADED" and addonLoaded == addonName then
        Config:Initialize()
    end
end)
