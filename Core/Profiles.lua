local addonName, WR = ...

-- Profiles module - handles rotation profiles and settings
local Profiles = {}
WR.Profiles = Profiles

-- State
local state = {
    currentClass = nil,
    currentSpec = nil,
    profiles = {}, -- Structure: [class][spec][profileName] = profileData
    activeProfile = nil,
}

-- Initialize the profiles system
function Profiles:Initialize()
    -- Get current class and spec
    state.currentClass = select(2, UnitClass("player"))
    state.currentSpec = GetSpecialization()
    
    -- Load profiles from saved variables
    self:LoadProfiles()
    
    -- Create a default profile if none exists
    self:EnsureDefaultProfile()
    
    -- Activate the last used profile or default
    local lastProfile = WR.Config:GetCurrentProfile()
    self:ActivateProfile(lastProfile)
    
    WR:Debug("Profiles system initialized")
end

-- Load profiles from saved variables
function Profiles:LoadProfiles()
    -- Get profiles from saved variables
    local classProfiles = WR.Config:GetChar("classProfiles") or {}
    
    -- Initialize the profiles structure if needed
    if not state.profiles[state.currentClass] then
        state.profiles[state.currentClass] = {}
    end
    
    if not state.profiles[state.currentClass][state.currentSpec] then
        state.profiles[state.currentClass][state.currentSpec] = {}
    end
    
    -- Load profiles for current class/spec
    if classProfiles[state.currentClass] and classProfiles[state.currentClass][state.currentSpec] then
        state.profiles[state.currentClass][state.currentSpec] = classProfiles[state.currentClass][state.currentSpec]
    end
end

-- Ensure a default profile exists
function Profiles:EnsureDefaultProfile()
    if not state.profiles[state.currentClass] then
        state.profiles[state.currentClass] = {}
    end
    
    if not state.profiles[state.currentClass][state.currentSpec] then
        state.profiles[state.currentClass][state.currentSpec] = {}
    end
    
    if not state.profiles[state.currentClass][state.currentSpec]["Default"] then
        -- Create a default profile
        state.profiles[state.currentClass][state.currentSpec]["Default"] = {
            name = "Default",
            description = "Default rotation profile",
            priority = {},
            cooldowns = {},
            defensives = {},
            utility = {},
            aoe = {},
            interrupts = true,
            talents = {},
            created = time(),
            modified = time(),
        }
        
        -- Save to config
        WR.Config:SaveClassProfile(state.profiles[state.currentClass][state.currentSpec]["Default"], "Default")
    end
}

-- Activate a profile
function Profiles:ActivateProfile(profileName)
    profileName = profileName or "Default"
    
    -- Check if profile exists
    if not state.profiles[state.currentClass] or
       not state.profiles[state.currentClass][state.currentSpec] or
       not state.profiles[state.currentClass][state.currentSpec][profileName] then
        
        -- Fallback to Default
        profileName = "Default"
        
        -- If still not found, create it
        if not state.profiles[state.currentClass] or
           not state.profiles[state.currentClass][state.currentSpec] or
           not state.profiles[state.currentClass][state.currentSpec][profileName] then
            self:EnsureDefaultProfile()
        end
    end
    
    -- Set as active profile
    state.activeProfile = state.profiles[state.currentClass][state.currentSpec][profileName]
    
    -- Save to config
    WR.Config:SetCurrentProfile(profileName)
    
    WR:Debug("Activated profile:", profileName)
    
    -- Apply the profile settings to the current rotation
    if WR.Classes[state.currentClass] and WR.Classes[state.currentClass].ApplyProfile then
        WR.Classes[state.currentClass]:ApplyProfile(state.activeProfile)
    end
    
    return true
end

-- Get the active profile
function Profiles:GetActiveProfile()
    return state.activeProfile
end

-- Get a profile by name
function Profiles:GetProfile(profileName)
    profileName = profileName or "Default"
    
    if not state.profiles[state.currentClass] or
       not state.profiles[state.currentClass][state.currentSpec] or
       not state.profiles[state.currentClass][state.currentSpec][profileName] then
        return nil
    end
    
    return state.profiles[state.currentClass][state.currentSpec][profileName]
end

-- Get all profiles for current class/spec
function Profiles:GetAllProfiles()
    if not state.profiles[state.currentClass] or
       not state.profiles[state.currentClass][state.currentSpec] then
        return {}
    end
    
    return state.profiles[state.currentClass][state.currentSpec]
end

-- Create a new profile
function Profiles:CreateProfile(profileName, basedOn)
    -- Generate a unique name if not provided
    if not profileName or profileName == "" then
        profileName = "Profile " .. date("%Y-%m-%d %H:%M:%S")
    end
    
    -- Check if profile already exists
    if state.profiles[state.currentClass] and
       state.profiles[state.currentClass][state.currentSpec] and
       state.profiles[state.currentClass][state.currentSpec][profileName] then
        
        -- Append a number to make it unique
        local i = 1
        local newName = profileName .. " " .. i
        while state.profiles[state.currentClass][state.currentSpec][newName] do
            i = i + 1
            newName = profileName .. " " .. i
        end
        profileName = newName
    end
    
    -- Get the base profile to copy from
    local baseProfile
    if basedOn and state.profiles[state.currentClass] and
       state.profiles[state.currentClass][state.currentSpec] and
       state.profiles[state.currentClass][state.currentSpec][basedOn] then
        baseProfile = state.profiles[state.currentClass][state.currentSpec][basedOn]
    else
        -- Use active profile as base
        baseProfile = state.activeProfile or self:GetProfile("Default")
    end
    
    -- Create the new profile
    local newProfile = CopyTable(baseProfile)
    newProfile.name = profileName
    newProfile.created = time()
    newProfile.modified = time()
    
    -- Save the new profile
    if not state.profiles[state.currentClass] then
        state.profiles[state.currentClass] = {}
    end
    
    if not state.profiles[state.currentClass][state.currentSpec] then
        state.profiles[state.currentClass][state.currentSpec] = {}
    end
    
    state.profiles[state.currentClass][state.currentSpec][profileName] = newProfile
    
    -- Save to config
    WR.Config:SaveClassProfile(newProfile, profileName)
    
    WR:Debug("Created new profile:", profileName)
    
    return profileName
end

-- Update a profile
function Profiles:UpdateProfile(profileName, profileData)
    profileName = profileName or "Default"
    
    -- Check if profile exists
    if not state.profiles[state.currentClass] or
       not state.profiles[state.currentClass][state.currentSpec] or
       not state.profiles[state.currentClass][state.currentSpec][profileName] then
        return false
    end
    
    -- Update the profile
    for k, v in pairs(profileData) do
        state.profiles[state.currentClass][state.currentSpec][profileName][k] = v
    end
    
    -- Update modification time
    state.profiles[state.currentClass][state.currentSpec][profileName].modified = time()
    
    -- If this is the active profile, update it
    if state.activeProfile and state.activeProfile.name == profileName then
        state.activeProfile = state.profiles[state.currentClass][state.currentSpec][profileName]
    end
    
    -- Save to config
    WR.Config:SaveClassProfile(state.profiles[state.currentClass][state.currentSpec][profileName], profileName)
    
    WR:Debug("Updated profile:", profileName)
    
    return true
end

-- Delete a profile
function Profiles:DeleteProfile(profileName)
    -- Cannot delete Default profile
    if profileName == "Default" then
        return false
    end
    
    -- Check if profile exists
    if not state.profiles[state.currentClass] or
       not state.profiles[state.currentClass][state.currentSpec] or
       not state.profiles[state.currentClass][state.currentSpec][profileName] then
        return false
    end
    
    -- Delete the profile
    state.profiles[state.currentClass][state.currentSpec][profileName] = nil
    
    -- If this was the active profile, switch to Default
    if state.activeProfile and state.activeProfile.name == profileName then
        self:ActivateProfile("Default")
    end
    
    -- Delete from config
    WR.Config:DeleteProfile(profileName)
    
    WR:Debug("Deleted profile:", profileName)
    
    return true
end

-- Export a profile to string
function Profiles:ExportProfile(profileName)
    profileName = profileName or state.activeProfile.name or "Default"
    
    -- Get the profile
    local profile = self:GetProfile(profileName)
    if not profile then
        return nil
    end
    
    -- Convert to string
    local profileString = WR.API.Serialize(profile)
    
    -- Compress and encode (in a real implementation)
    local compressed = WR.API.Compress(profileString)
    local encoded = WR.API.Encode(compressed)
    
    return encoded
end

-- Import a profile from string
function Profiles:ImportProfile(encodedString, profileName)
    if not encodedString or encodedString == "" then
        return nil, "Empty profile string"
    end
    
    -- Try to decode the profile
    local success, result = pcall(function()
        local compressed = WR.API.Decode(encodedString)
        local profileString = WR.API.Decompress(compressed)
        local profile = WR.API.Deserialize(profileString)
        
        if not profile or type(profile) ~= "table" then
            return nil, "Invalid profile data"
        end
        
        -- Use specified name or generate one
        if profileName and profileName ~= "" then
            profile.name = profileName
        else
            profileName = profile.name .. " (Imported)"
            profile.name = profileName
        }
        
        -- Set created/modified times
        profile.imported = true
        profile.created = time()
        profile.modified = time()
        
        -- Save the profile
        if not state.profiles[state.currentClass] then
            state.profiles[state.currentClass] = {}
        end
        
        if not state.profiles[state.currentClass][state.currentSpec] then
            state.profiles[state.currentClass][state.currentSpec] = {}
        end
        
        state.profiles[state.currentClass][state.currentSpec][profileName] = profile
        
        -- Save to config
        WR.Config:SaveClassProfile(profile, profileName)
        
        return profileName
    end)
    
    if not success then
        return nil, "Failed to import profile: " .. result
    end
    
    WR:Debug("Imported profile:", result)
    
    return result
end

-- Check if a profile exists
function Profiles:ProfileExists(profileName)
    return state.profiles[state.currentClass] and
           state.profiles[state.currentClass][state.currentSpec] and
           state.profiles[state.currentClass][state.currentSpec][profileName] ~= nil
end

-- Get current class
function Profiles:GetCurrentClass()
    return state.currentClass
end

-- Get current spec
function Profiles:GetCurrentSpec()
    return state.currentSpec
end

-- Update when spec changes
function Profiles:UpdateSpec()
    local newSpec = GetSpecialization()
    if newSpec ~= state.currentSpec then
        state.currentSpec = newSpec
        
        -- Load profiles for the new spec
        self:LoadProfiles()
        
        -- Ensure default profile exists
        self:EnsureDefaultProfile()
        
        -- Activate the last used profile for this spec
        local lastProfile = WR.Config:GetCurrentProfile()
        self:ActivateProfile(lastProfile)
        
        WR:Debug("Updated to spec:", state.currentSpec)
    end
}
