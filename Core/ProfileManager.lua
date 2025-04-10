local addonName, WR = ...

-- ProfileManager module for handling user profiles and settings
local ProfileManager = {}
WR.ProfileManager = ProfileManager

-- Profile data
ProfileManager.profiles = {}
ProfileManager.defaultProfile = nil
ProfileManager.currentProfile = nil
ProfileManager.classProfiles = {}
ProfileManager.profileHistory = {}

-- Initialize ProfileManager module
function ProfileManager:Initialize()
    -- Load saved profiles from DB
    self:LoadProfiles()
    
    -- Create default profiles if needed
    self:EnsureDefaultProfiles()
    
    -- Load the current profile
    self:LoadProfile(self:GetCurrentProfileName())
    
    -- Register callbacks for settings changes
    self:RegisterCallbacks()
    
    WR:Debug("ProfileManager module initialized")
end

-- Load profiles from saved variables
function ProfileManager:LoadProfiles()
    -- Reset profile data
    self.profiles = {}
    self.classProfiles = {}
    self.profileHistory = {}
    
    -- Load profiles from character DB
    if WR.charDB and WR.charDB.classProfiles then
        self.classProfiles = WR.charDB.classProfiles
    end
    
    if WR.charDB and WR.charDB.profileHistory then
        self.profileHistory = WR.charDB.profileHistory
    end
    
    -- Load global profiles from global DB
    if WindrunnerRotationsDB and WindrunnerRotationsDB.profiles then
        for name, profileData in pairs(WindrunnerRotationsDB.profiles) do
            self.profiles[name] = profileData
        end
    end
    
    -- Set default profile
    self.defaultProfile = "Default"
    
    -- Set current profile to the one saved in character DB
    if WR.charDB and WR.charDB.currentProfile then
        self.currentProfile = WR.charDB.currentProfile
    else
        self.currentProfile = self.defaultProfile
    end
    
    WR:Debug("Loaded profiles:", self:GetProfileCount())
end

-- Create default profiles if none exist
function ProfileManager:EnsureDefaultProfiles()
    -- Create default profile if it doesn't exist
    if not self.profiles[self.defaultProfile] then
        self.profiles[self.defaultProfile] = self:CreateDefaultProfile()
        self:SaveProfiles()
    end
    
    -- Create class-specific default profiles
    local _, playerClass = UnitClass("player")
    if playerClass then
        -- Create class default profile if it doesn't exist
        local classDefaultName = playerClass .. " Default"
        if not self.profiles[classDefaultName] then
            self.profiles[classDefaultName] = self:CreateClassDefaultProfile(playerClass)
            self:SaveProfiles()
        end
        
        -- Create spec default profiles
        for specIndex = 1, GetNumSpecializations() do
            local specID = GetSpecializationInfo(specIndex)
            if specID then
                local specName = select(2, GetSpecializationInfo(specIndex))
                if specName then
                    local specProfileName = playerClass .. " " .. specName
                    if not self.profiles[specProfileName] then
                        self.profiles[specProfileName] = self:CreateSpecDefaultProfile(playerClass, specID)
                        self:SaveProfiles()
                    end
                end
            end
        end
    end
end

-- Create a default profile with general settings
function ProfileManager:CreateDefaultProfile()
    return {
        name = "Default",
        settings = {
            enabled = true,
            enableAutoTargeting = true,
            enableInterrupts = true,
            enableDefensives = true,
            enableCooldowns = true,
            enableAOE = true,
            enableDungeonAwareness = true,
            rotationSpeed = 100, -- milliseconds
            minimapIcon = { hide = false },
            UI = {
                scale = 1.0,
                locked = false,
                position = { point = "CENTER", x = 0, y = 0 },
            },
        },
        rotationSettings = {
            -- General rotation settings
            priorityTargets = true,
            autoTarget = true,
            focusInterrupts = true,
            defensiveThreshold = 60, -- Health percentage
            burstOnCooldown = false,
            useMovementAbilities = true,
            ccControl = true,
        },
        dungeonSettings = {
            -- Dungeon-specific settings
            enablePathfinding = true,
            automateInterrupts = true,
            avoidMechanics = true,
            autoTaunt = false,
            autoCC = true,
            smartTargeting = true,
            mythicPlusAffixAware = true,
        },
        classSettings = {
            -- Class-specific settings are added in class default profiles
        },
        version = WR.version,
        created = time(),
        lastModified = time(),
    }
end

-- Create a class-specific default profile
function ProfileManager:CreateClassDefaultProfile(className)
    -- Start with default profile
    local profile = self:CreateDefaultProfile()
    
    -- Set name
    profile.name = className .. " Default"
    
    -- Add class-specific settings
    profile.classSettings = {
        className = className,
        useClassDefaults = true,
    }
    
    -- Adjust based on role
    if className == "WARRIOR" or className == "DEATHKNIGHT" or className == "DEMONHUNTER" or className == "DRUID" or className == "PALADIN" or className == "MONK" then
        -- Tank specs might exist for this class
        profile.rotationSettings.defensiveThreshold = 70
        profile.dungeonSettings.autoTaunt = true
    end
    
    if className == "PRIEST" or className == "DRUID" or className == "PALADIN" or className == "MONK" or className == "SHAMAN" then
        -- Healing specs might exist for this class
        profile.rotationSettings.focusHealing = true
        profile.dungeonSettings.healingPriority = "Tank"
    end
    
    return profile
end

-- Create a spec-specific default profile
function ProfileManager:CreateSpecDefaultProfile(className, specID)
    -- Start with class default profile
    local classProfile = self:GetProfile(className .. " Default") or self:CreateClassDefaultProfile(className)
    local profile = self:CloneProfile(classProfile)
    
    -- Get spec name
    local specName = select(2, GetSpecializationInfoByID(specID))
    if not specName then
        specName = "Unknown"
    end
    
    -- Set name
    profile.name = className .. " " .. specName
    
    -- Add spec-specific settings
    profile.classSettings.specID = specID
    profile.classSettings.specName = specName
    
    -- Adjust settings based on spec role
    local role = select(5, GetSpecializationInfoByID(specID))
    
    if role == "TANK" then
        profile.rotationSettings.defensiveThreshold = 70
        profile.dungeonSettings.autoTaunt = true
        profile.rotationSettings.burstOnCooldown = false
    elseif role == "HEALER" then
        profile.rotationSettings.focusHealing = true
        profile.dungeonSettings.healingPriority = "Tank"
        profile.rotationSettings.burstOnCooldown = false
    elseif role == "DAMAGER" then
        profile.rotationSettings.burstOnCooldown = true
        profile.rotationSettings.defensiveThreshold = 50
    end
    
    -- Spec-specific tweaks
    if className == "MAGE" then
        if specName == "Fire" then
            profile.rotationSettings.burstAlignment = "Combustion"
        elseif specName == "Arcane" then
            profile.rotationSettings.burstAlignment = "ArcanePower"
        elseif specName == "Frost" then
            profile.rotationSettings.burstAlignment = "IcyVeins"
        end
    elseif className == "WARRIOR" then
        if specName == "Arms" then
            profile.rotationSettings.burstAlignment = "Colossus"
        elseif specName == "Fury" then
            profile.rotationSettings.burstAlignment = "Recklessness"
        end
    elseif className == "DRUID" then
        if specName == "Balance" then
            profile.rotationSettings.burstAlignment = "Celestial"
        elseif specName == "Feral" then
            profile.rotationSettings.burstAlignment = "Berserk"
        end
    end
    
    return profile
end

-- Clone a profile
function ProfileManager:CloneProfile(sourceProfile)
    if not sourceProfile then return self:CreateDefaultProfile() end
    
    -- Deep copy the profile
    local profile = {}
    for k, v in pairs(sourceProfile) do
        if type(v) == "table" then
            profile[k] = {}
            for k2, v2 in pairs(v) do
                profile[k][k2] = v2
            end
        else
            profile[k] = v
        end
    end
    
    return profile
end

-- Load a specific profile
function ProfileManager:LoadProfile(profileName)
    -- Default to Default profile if the requested one doesn't exist
    if not profileName or not self.profiles[profileName] then
        profileName = self.defaultProfile
    end
    
    -- Get the profile data
    local profileData = self.profiles[profileName]
    
    -- Set as current profile
    self.currentProfile = profileName
    
    -- Save to character DB
    if WR.charDB then
        WR.charDB.currentProfile = profileName
    end
    
    -- Apply settings
    self:ApplyProfileSettings(profileData)
    
    -- Add to history
    self:AddToProfileHistory(profileName)
    
    WR:Debug("Loaded profile:", profileName)
    
    -- Broadcast profile changed event
    WR:TriggerEvent("PROFILE_CHANGED", profileName, profileData)
    
    return profileData
end

-- Apply profile settings to the addon
function ProfileManager:ApplyProfileSettings(profileData)
    if not profileData or not profileData.settings then return end
    
    -- Apply general settings
    for key, value in pairs(profileData.settings) do
        if key ~= "UI" and key ~= "minimapIcon" then
            WR.db[key] = value
        end
    end
    
    -- Apply UI settings
    if profileData.settings.UI then
        for key, value in pairs(profileData.settings.UI) do
            WR.db.UI[key] = value
        end
    end
    
    -- Apply minimap icon settings
    if profileData.settings.minimapIcon then
        for key, value in pairs(profileData.settings.minimapIcon) do
            WR.db.minimapIcon[key] = value
        end
    end
    
    -- Apply rotation settings if available
    if profileData.rotationSettings and WR.Rotation then
        for key, value in pairs(profileData.rotationSettings) do
            WR.Rotation:SetSetting(key, value)
        end
    end
    
    -- Apply dungeon settings if available
    if profileData.dungeonSettings and WR.DungeonIntelligence then
        for key, value in pairs(profileData.dungeonSettings) do
            -- Apply setting to DungeonIntelligence module
            if type(WR.DungeonIntelligence[key]) ~= "function" then
                WR.DungeonIntelligence[key] = value
            end
        end
    end
    
    -- Apply class settings if available
    if profileData.classSettings and WR.Classes then
        local _, playerClass = UnitClass("player")
        if playerClass and WR.Classes[playerClass] and profileData.classSettings.className == playerClass then
            local classModule = WR.Classes[playerClass]
            
            -- Set class-specific settings
            for key, value in pairs(profileData.classSettings) do
                if key ~= "className" and key ~= "specID" and key ~= "specName" and
                   type(classModule[key]) ~= "function" then
                    classModule[key] = value
                end
            end
            
            -- If current specialization matches profile's spec, apply spec settings
            if profileData.classSettings.specID and profileData.classSettings.specID == WR.currentSpec then
                -- Apply spec-specific settings
                if classModule.LoadSpecSettings then
                    classModule:LoadSpecSettings(profileData.classSettings)
                end
            end
        end
    end
end

-- Add a profile to the history
function ProfileManager:AddToProfileHistory(profileName)
    -- Check if this profile is already in history
    for i, name in ipairs(self.profileHistory) do
        if name == profileName then
            -- Remove it so we can add it to the front
            table.remove(self.profileHistory, i)
            break
        end
    end
    
    -- Add to front of history
    table.insert(self.profileHistory, 1, profileName)
    
    -- Limit history to 10 entries
    while #self.profileHistory > 10 do
        table.remove(self.profileHistory)
    end
    
    -- Save to character DB
    if WR.charDB then
        WR.charDB.profileHistory = self.profileHistory
    end
end

-- Save all profiles to DB
function ProfileManager:SaveProfiles()
    -- Save to global DB
    if not WindrunnerRotationsDB then
        WindrunnerRotationsDB = {}
    end
    
    WindrunnerRotationsDB.profiles = {}
    
    for name, profileData in pairs(self.profiles) do
        WindrunnerRotationsDB.profiles[name] = profileData
    end
    
    -- Save to character DB
    if WR.charDB then
        WR.charDB.classProfiles = self.classProfiles
        WR.charDB.profileHistory = self.profileHistory
        WR.charDB.currentProfile = self.currentProfile
    end
    
    WR:Debug("Saved profiles to DB")
end

-- Get the name of the current profile
function ProfileManager:GetCurrentProfileName()
    return self.currentProfile or self.defaultProfile
end

-- Get profile data by name
function ProfileManager:GetProfile(profileName)
    return self.profiles[profileName]
end

-- Get the current profile data
function ProfileManager:GetCurrentProfile()
    return self:GetProfile(self:GetCurrentProfileName())
end

-- Create a new profile
function ProfileManager:CreateProfile(profileName, basedOn)
    if not profileName or profileName == "" then
        profileName = "Profile " .. tostring(self:GetProfileCount() + 1)
    end
    
    -- Check if profile already exists
    if self.profiles[profileName] then
        -- Append a number to make it unique
        local i = 1
        local newName = profileName .. " " .. tostring(i)
        while self.profiles[newName] do
            i = i + 1
            newName = profileName .. " " .. tostring(i)
        end
        profileName = newName
    end
    
    -- Create the profile
    local baseProfile
    if basedOn and self.profiles[basedOn] then
        baseProfile = self:CloneProfile(self.profiles[basedOn])
    else
        baseProfile = self:CloneProfile(self:GetCurrentProfile())
    end
    
    -- Set the new profile name
    baseProfile.name = profileName
    baseProfile.created = time()
    baseProfile.lastModified = time()
    
    -- Add to profiles list
    self.profiles[profileName] = baseProfile
    
    -- Save profiles
    self:SaveProfiles()
    
    WR:Debug("Created new profile:", profileName)
    
    return profileName
end

-- Delete a profile
function ProfileManager:DeleteProfile(profileName)
    -- Don't delete the default profile
    if profileName == self.defaultProfile then
        return false
    end
    
    -- Remove from profiles list
    self.profiles[profileName] = nil
    
    -- If this was the current profile, switch to default
    if self.currentProfile == profileName then
        self:LoadProfile(self.defaultProfile)
    end
    
    -- Remove from history
    for i, name in ipairs(self.profileHistory) do
        if name == profileName then
            table.remove(self.profileHistory, i)
            break
        end
    end
    
    -- Save profiles
    self:SaveProfiles()
    
    WR:Debug("Deleted profile:", profileName)
    
    return true
end

-- Rename a profile
function ProfileManager:RenameProfile(oldName, newName)
    -- Check if the old profile exists
    if not self.profiles[oldName] then
        return false
    end
    
    -- Check if the new name would conflict
    if self.profiles[newName] then
        return false
    end
    
    -- Get the profile data
    local profileData = self.profiles[oldName]
    
    -- Update the name
    profileData.name = newName
    profileData.lastModified = time()
    
    -- Add to profiles with new name
    self.profiles[newName] = profileData
    
    -- Remove old name
    self.profiles[oldName] = nil
    
    -- Update current profile if needed
    if self.currentProfile == oldName then
        self.currentProfile = newName
    end
    
    -- Update history
    for i, name in ipairs(self.profileHistory) do
        if name == oldName then
            self.profileHistory[i] = newName
            break
        end
    end
    
    -- Save profiles
    self:SaveProfiles()
    
    WR:Debug("Renamed profile:", oldName, "to", newName)
    
    return true
end

-- Update a profile with new settings
function ProfileManager:UpdateProfile(profileName, newSettings)
    -- Check if the profile exists
    if not self.profiles[profileName] then
        return false
    end
    
    -- Get the profile data
    local profileData = self.profiles[profileName]
    
    -- Update settings
    if newSettings.settings then
        for key, value in pairs(newSettings.settings) do
            profileData.settings[key] = value
        end
    end
    
    -- Update rotation settings
    if newSettings.rotationSettings then
        if not profileData.rotationSettings then
            profileData.rotationSettings = {}
        end
        
        for key, value in pairs(newSettings.rotationSettings) do
            profileData.rotationSettings[key] = value
        end
    end
    
    -- Update dungeon settings
    if newSettings.dungeonSettings then
        if not profileData.dungeonSettings then
            profileData.dungeonSettings = {}
        end
        
        for key, value in pairs(newSettings.dungeonSettings) do
            profileData.dungeonSettings[key] = value
        end
    end
    
    -- Update class settings
    if newSettings.classSettings then
        if not profileData.classSettings then
            profileData.classSettings = {}
        end
        
        for key, value in pairs(newSettings.classSettings) do
            profileData.classSettings[key] = value
        end
    end
    
    -- Update timestamp
    profileData.lastModified = time()
    
    -- Save profiles
    self:SaveProfiles()
    
    -- If this is the current profile, apply settings
    if self.currentProfile == profileName then
        self:ApplyProfileSettings(profileData)
    end
    
    WR:Debug("Updated profile:", profileName)
    
    return true
end

-- Get list of all profiles
function ProfileManager:GetProfileList()
    local list = {}
    
    for name, _ in pairs(self.profiles) do
        table.insert(list, name)
    end
    
    table.sort(list)
    
    return list
end

-- Get number of profiles
function ProfileManager:GetProfileCount()
    local count = 0
    
    for _ in pairs(self.profiles) do
        count = count + 1
    end
    
    return count
end

-- Get list of recently used profiles
function ProfileManager:GetRecentProfiles(count)
    count = count or 5
    
    local list = {}
    
    for i = 1, math.min(count, #self.profileHistory) do
        table.insert(list, self.profileHistory[i])
    end
    
    return list
end

-- Export a profile to string
function ProfileManager:ExportProfile(profileName)
    -- Get the profile
    local profile = self:GetProfile(profileName)
    if not profile then
        return nil
    end
    
    -- Convert to string
    local serialized = self:Serialize(profile)
    
    -- Encode for safe transmission
    local encoded = self:Encode(serialized)
    
    return encoded
end

-- Import a profile from string
function ProfileManager:ImportProfile(encoded)
    -- Decode
    local serialized = self:Decode(encoded)
    if not serialized then
        return nil, "Invalid encoded data"
    end
    
    -- Deserialize
    local success, profile = self:Deserialize(serialized)
    if not success or not profile or type(profile) ~= "table" or not profile.name then
        return nil, "Invalid profile data"
    end
    
    -- Check for version compatibility
    if profile.version and profile.version > WR.version then
        return nil, "Profile is from a newer version of the addon"
    end
    
    -- Create the profile with a temporary name
    local tempName = "Imported " .. profile.name
    
    -- Check if profile already exists
    if self.profiles[tempName] then
        -- Append a number to make it unique
        local i = 1
        local newName = tempName .. " " .. tostring(i)
        while self.profiles[newName] do
            i = i + 1
            newName = tempName .. " " .. tostring(i)
        end
        tempName = newName
    end
    
    -- Set the name
    profile.name = tempName
    profile.imported = true
    profile.importedAt = time()
    
    -- Add to profiles
    self.profiles[tempName] = profile
    
    -- Save profiles
    self:SaveProfiles()
    
    WR:Debug("Imported profile:", tempName)
    
    return tempName
end

-- Register callbacks for settings changes
function ProfileManager:RegisterCallbacks()
    -- Register callback for when settings change
    WR:RegisterCallback("SETTINGS_CHANGED", function(key, value)
        self:OnSettingChanged(key, value)
    end)
    
    -- Register callback for when specialization changes
    WR:RegisterCallback("SPECIALIZATION_CHANGED", function(specID)
        self:OnSpecializationChanged(specID)
    end)
    
    -- Register callback for when entering a dungeon
    WR:RegisterCallback("DUNGEON_CHANGED", function(dungeonInfo)
        self:OnDungeonChanged(dungeonInfo)
    end)
end

-- Handle setting changes
function ProfileManager:OnSettingChanged(key, value)
    -- Update the current profile
    local currentProfile = self:GetCurrentProfile()
    if not currentProfile then return end
    
    -- Check which category the setting belongs to
    if currentProfile.settings[key] ~= nil then
        -- General setting
        currentProfile.settings[key] = value
    elseif key:find("rotation.") == 1 then
        -- Rotation setting
        local rotationKey = key:sub(10)
        if not currentProfile.rotationSettings then
            currentProfile.rotationSettings = {}
        end
        currentProfile.rotationSettings[rotationKey] = value
    elseif key:find("dungeon.") == 1 then
        -- Dungeon setting
        local dungeonKey = key:sub(9)
        if not currentProfile.dungeonSettings then
            currentProfile.dungeonSettings = {}
        end
        currentProfile.dungeonSettings[dungeonKey] = value
    elseif key:find("class.") == 1 then
        -- Class setting
        local classKey = key:sub(7)
        if not currentProfile.classSettings then
            currentProfile.classSettings = {}
        end
        currentProfile.classSettings[classKey] = value
    end
    
    -- Update timestamp
    currentProfile.lastModified = time()
    
    -- Save profiles
    self:SaveProfiles()
end

-- Handle specialization changes
function ProfileManager:OnSpecializationChanged(specID)
    -- Check if we have a spec-specific profile
    local _, playerClass = UnitClass("player")
    local specName = select(2, GetSpecializationInfoByID(specID))
    
    if playerClass and specName then
        local specProfileName = playerClass .. " " .. specName
        
        -- Check if this profile exists
        if self.profiles[specProfileName] then
            -- Switch to the spec profile
            self:LoadProfile(specProfileName)
        else
            -- Create a spec-specific profile
            self:CreateProfile(specProfileName, playerClass .. " Default")
            self:LoadProfile(specProfileName)
        end
    end
end

-- Handle dungeon changes
function ProfileManager:OnDungeonChanged(dungeonInfo)
    -- For future implementation - could auto-switch to dungeon-specific profiles
    -- For now, we just log
    if dungeonInfo then
        WR:Debug("Entered dungeon:", dungeonInfo.name)
    else
        WR:Debug("Left dungeon")
    end
end

-- Simplified serialization (would use AceSerializer in a real addon)
function ProfileManager:Serialize(data)
    return WR.Util.serialize(data)
end

-- Simplified deserialization
function ProfileManager:Deserialize(serialized)
    return pcall(WR.Util.deserialize, serialized)
end

-- Simple encoding/decoding (would use LibDeflate in a real addon)
function ProfileManager:Encode(data)
    -- Base64 encode
    return WR.Util.encode(data)
end

-- Simple decoding
function ProfileManager:Decode(encoded)
    -- Base64 decode
    return WR.Util.decode(encoded)
end

-- Save a class-specific profile
function ProfileManager:SaveClassProfile(profileData, name)
    if not name or name == "" then
        local _, playerClass = UnitClass("player")
        local spec = GetSpecialization()
        local specName = spec and select(2, GetSpecializationInfo(spec)) or "Unknown"
        
        name = playerClass .. " " .. specName .. " Custom"
    end
    
    -- Create new profile or update existing
    if self.profiles[name] then
        self:UpdateProfile(name, profileData)
    else
        -- Clone current profile
        local newProfile = self:CloneProfile(self:GetCurrentProfile())
        
        -- Apply new data
        for key, value in pairs(profileData) do
            if type(value) == "table" then
                if not newProfile[key] then
                    newProfile[key] = {}
                end
                
                for k, v in pairs(value) do
                    newProfile[key][k] = v
                end
            else
                newProfile[key] = value
            end
        end
        
        -- Set name and timestamps
        newProfile.name = name
        newProfile.created = time()
        newProfile.lastModified = time()
        
        -- Save to profiles
        self.profiles[name] = newProfile
        self:SaveProfiles()
        
        -- Switch to new profile
        self:LoadProfile(name)
    end
    
    -- Save to class profiles
    local _, playerClass = UnitClass("player")
    if not self.classProfiles[playerClass] then
        self.classProfiles[playerClass] = {}
    end
    
    self.classProfiles[playerClass][name] = true
    self:SaveProfiles()
    
    return name
end

-- Return module
return ProfileManager