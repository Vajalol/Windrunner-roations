local addonName, WR = ...

-- Profile Manager module - handles saving and loading user-specific rotation profiles
local ProfileManager = {}
WR.ProfileManager = ProfileManager

-- State
local state = {
    currentProfile = "Default",
    profiles = {},
    classProfiles = {},
    defaultSettings = {},
    profileSettings = {},
    lastProfileUpdate = 0,
    profileHistory = {},
    presetProfiles = {},
    profileMetadata = {},
    autosaveEnabled = true,
    unsavedChanges = false
}

-- Initialize the module
function ProfileManager:Initialize()
    -- Load saved profiles from saved variables
    if WR.charDB and WR.charDB.classProfiles then
        state.classProfiles = WR.charDB.classProfiles
    end
    
    if WR.charDB and WR.charDB.currentProfile then
        state.currentProfile = WR.charDB.currentProfile
    end
    
    -- Default settings for a new profile
    state.defaultSettings = {
        -- General settings
        enabled = true,
        enableAutoTargeting = true,
        enableInterrupts = true,
        enableDefensives = true,
        enableCooldowns = false,
        enableAOE = true,
        enableDungeonAwareness = true,
        saveResourcesForBurst = false,
        autoSwitchTargets = true,
        rotationSpeed = 100, -- milliseconds
        
        -- UI settings
        minimapIcon = { hide = false },
        UI = {
            scale = 1.0,
            locked = false,
            position = { point = "CENTER", x = 0, y = 0 },
            showCooldowns = true,
            showResourceBar = true,
            showDebuffs = true,
            showBuffs = true,
            iconSize = 32,
            colorEnabled = true,
            theme = "dark",
        },
        
        -- Class specific settings
        classSpecific = {},
        
        -- Advanced settings
        advancedMode = false,
        customCodeEnabled = false,
        customPriorities = {},
        abilityRanks = {},
        targetingCriteria = {},
        simulationEnabled = false,
        
        -- Dungeon settings
        dungeonAwarenessLevel = 3, -- 1-5 scale for how much to focus on dungeon mechanics
        mythicPlusModeEnabled = true,
        priorityDispelsEnabled = true,
        interruptPriority = 70, -- 0-100 interrupt chance percentage
    }
    
    -- Create default profile if none exists
    if not state.classProfiles["Default"] then
        self:CreateProfile("Default", state.defaultSettings)
    end
    
    -- Load any preset profiles
    self:LoadPresetProfiles()
    
    -- Load the current profile
    self:LoadProfile(state.currentProfile)
    
    -- Create frame for events
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGOUT")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGOUT" then
            ProfileManager:SaveChanges()
        end
    end)
    
    WR:Debug("Profile Manager initialized, current profile:", state.currentProfile)
end

-- Load preset profiles for different specs/classes
function ProfileManager:LoadPresetProfiles()
    -- Example presets that could be included with the addon
    state.presetProfiles = {
        -- Mage presets
        ["Arcane Mage: Single Target"] = {
            description = "Optimized for single-target Arcane Mage damage in raid encounters",
            class = "MAGE",
            spec = 62, -- Arcane
            author = "WindrunnerDev",
            settings = {
                enableCooldowns = true,
                enableAOE = false,
                saveResourcesForBurst = true,
                classSpecific = {
                    conserveManaThreshold = 70,
                    burstManaThreshold = 50,
                    useCooldownsWithTotM = true,
                    arcaneBarrageDumpAt = 30,
                }
            }
        },
        ["Fire Mage: AoE Mythic+"] = {
            description = "Optimized for AoE Fire Mage damage in Mythic+ dungeons",
            class = "MAGE",
            spec = 63, -- Fire
            author = "WindrunnerDev",
            settings = {
                enableCooldowns = true,
                enableAOE = true,
                saveResourcesForBurst = false,
                enableDungeonAwareness = true,
                dungeonAwarenessLevel = 4,
                classSpecific = {
                    flamestrikePriority = 3,
                    phoenixFlamesChargeThreshold = 2,
                    heatupConservation = true
                }
            }
        },
        
        -- Hunter presets
        ["Beast Mastery: Raid Single Target"] = {
            description = "Optimized for single-target Beast Mastery Hunter damage in raids",
            class = "HUNTER",
            spec = 253, -- Beast Mastery
            author = "WindrunnerDev",
            settings = {
                enableCooldowns = true,
                enableAOE = false,
                saveResourcesForBurst = true,
                classSpecific = {
                    aspectTiming = "withBestial",
                    barbedShotStrategy = "frenzyFocus",
                    killCommandPriority = 90,
                    petManagement = "offensive"
                }
            }
        },
        
        -- Warrior presets
        ["Fury Warrior: AoE Cleave"] = {
            description = "Optimized for Fury Warrior AoE and cleave damage",
            class = "WARRIOR",
            spec = 72, -- Fury
            author = "WindrunnerDev",
            settings = {
                enableCooldowns = true,
                enableAOE = true,
                saveResourcesForBurst = false,
                classSpecific = {
                    whirlwindThreshold = 2,
                    enragePriority = "high",
                    executeThreshold = 35,
                    rampage = "onEnrage"
                }
            }
        },
        
        -- Paladin presets
        ["Retribution Paladin: Burst"] = {
            description = "Optimized for Retribution Paladin burst damage",
            class = "PALADIN",
            spec = 70, -- Retribution
            author = "WindrunnerDev",
            settings = {
                enableCooldowns = true,
                enableAOE = false,
                saveResourcesForBurst = true,
                classSpecific = {
                    judgmentFirst = true,
                    holyPowerManagement = "aggressive",
                    executePhase = "highPriority",
                    wakeOfAshes = "onCooldown"
                }
            }
        }
    }
    
    -- Register preset profiles' metadata
    for name, preset in pairs(state.presetProfiles) do
        state.profileMetadata[name] = {
            description = preset.description,
            class = preset.class,
            spec = preset.spec,
            author = preset.author,
            isPreset = true,
            lastUpdate = time()
        }
    end
end

-- Create a new profile with specific settings
function ProfileManager:CreateProfile(name, settings)
    if not name or name == "" then
        WR:Debug("Invalid profile name")
        return false
    end
    
    -- Don't overwrite existing profiles without explicit confirmation
    if state.classProfiles[name] and name ~= state.currentProfile then
        WR:Debug("Profile already exists:", name)
        return false
    end
    
    -- Create a new profile by combining default settings with provided settings
    local newSettings = self:CopyTable(state.defaultSettings)
    if settings then
        self:MergeSettings(newSettings, settings)
    end
    
    -- Store the profile
    state.classProfiles[name] = newSettings
    
    -- Update metadata
    state.profileMetadata[name] = {
        description = settings and settings.description or "Custom profile",
        class = select(2, UnitClass("player")),
        spec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil,
        author = "Player",
        isPreset = false,
        lastUpdate = time()
    }
    
    -- Save to DB
    self:SaveChanges()
    
    WR:Debug("Created profile:", name)
    return true
end

-- Load a profile (preset or custom)
function ProfileManager:LoadProfile(name)
    -- First check existing profiles
    if state.classProfiles[name] then
        state.profileSettings = self:CopyTable(state.classProfiles[name])
        state.currentProfile = name
        
        -- Save current profile name to DB
        WR.charDB.currentProfile = name
        
        -- Apply settings to the addon
        self:ApplyProfileSettings()
        
        -- Add to history
        table.insert(state.profileHistory, {
            name = name,
            time = time()
        })
        
        -- Keep history to reasonable size
        if #state.profileHistory > 10 then
            table.remove(state.profileHistory, 1)
        end
        
        WR:Debug("Loaded profile:", name)
        return true
    end
    
    -- Then check preset profiles
    if state.presetProfiles[name] then
        local preset = state.presetProfiles[name]
        
        -- Check if preset is compatible with current class/spec
        local playerClass = select(2, UnitClass("player"))
        local playerSpec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil
        
        if preset.class ~= playerClass or (preset.spec and preset.spec ~= playerSpec) then
            WR:Debug("Preset profile not compatible with current class/spec")
            return false
        end
        
        -- Create new profile from preset
        local newSettings = self:CopyTable(state.defaultSettings)
        self:MergeSettings(newSettings, preset.settings)
        
        -- Store and apply
        state.classProfiles[name] = newSettings
        state.profileSettings = self:CopyTable(newSettings)
        state.currentProfile = name
        
        -- Save current profile name to DB
        WR.charDB.currentProfile = name
        
        -- Apply settings to the addon
        self:ApplyProfileSettings()
        
        -- Add to history
        table.insert(state.profileHistory, {
            name = name,
            time = time()
        })
        
        -- Keep history to reasonable size
        if #state.profileHistory > 10 then
            table.remove(state.profileHistory, 1)
        end
        
        WR:Debug("Loaded preset profile:", name)
        return true
    end
    
    WR:Debug("Profile not found:", name)
    return false
end

-- Save current profile
function ProfileManager:SaveCurrentProfile()
    if not state.currentProfile or state.currentProfile == "" then
        WR:Debug("No current profile to save")
        return false
    end
    
    -- Store current settings to profile
    state.classProfiles[state.currentProfile] = self:CopyTable(state.profileSettings)
    
    -- Update metadata
    if state.profileMetadata[state.currentProfile] then
        state.profileMetadata[state.currentProfile].lastUpdate = time()
    else
        state.profileMetadata[state.currentProfile] = {
            description = "Custom profile",
            class = select(2, UnitClass("player")),
            spec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil,
            author = "Player",
            isPreset = false,
            lastUpdate = time()
        }
    end
    
    -- Mark as having unsaved changes
    state.unsavedChanges = true
    
    -- Autosave if enabled
    if state.autosaveEnabled then
        self:SaveChanges()
    end
    
    WR:Debug("Saved current profile:", state.currentProfile)
    return true
end

-- Save current profile with a new name
function ProfileManager:SaveProfileAs(name)
    if not name or name == "" then
        WR:Debug("Invalid profile name")
        return false
    end
    
    -- Store current settings to new profile name
    state.classProfiles[name] = self:CopyTable(state.profileSettings)
    
    -- Update current profile
    state.currentProfile = name
    
    -- Update metadata
    state.profileMetadata[name] = {
        description = "Custom profile",
        class = select(2, UnitClass("player")),
        spec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil,
        author = "Player",
        isPreset = false,
        lastUpdate = time()
    }
    
    -- Save to DB
    WR.charDB.currentProfile = name
    self:SaveChanges()
    
    WR:Debug("Saved profile as:", name)
    return true
end

-- Delete a profile
function ProfileManager:DeleteProfile(name)
    if not name or name == "" or name == "Default" then
        WR:Debug("Cannot delete Default profile or invalid name")
        return false
    end
    
    if not state.classProfiles[name] then
        WR:Debug("Profile not found:", name)
        return false
    end
    
    -- Remove profile
    state.classProfiles[name] = nil
    
    -- Also remove metadata
    state.profileMetadata[name] = nil
    
    -- If this was the current profile, switch to Default
    if state.currentProfile == name then
        self:LoadProfile("Default")
    end
    
    -- Save changes
    self:SaveChanges()
    
    WR:Debug("Deleted profile:", name)
    return true
end

-- Save changes to DB
function ProfileManager:SaveChanges()
    -- Save to character DB
    WR.charDB.classProfiles = state.classProfiles
    
    state.unsavedChanges = false
    state.lastProfileUpdate = time()
    
    WR:Debug("Saved all profile changes to DB")
    return true
end

-- Apply current profile settings to the addon
function ProfileManager:ApplyProfileSettings()
    -- Apply general settings
    WR.Config:Set("enabled", state.profileSettings.enabled)
    WR.Config:Set("enableAutoTargeting", state.profileSettings.enableAutoTargeting)
    WR.Config:Set("enableInterrupts", state.profileSettings.enableInterrupts)
    WR.Config:Set("enableDefensives", state.profileSettings.enableDefensives)
    WR.Config:Set("enableCooldowns", state.profileSettings.enableCooldowns)
    WR.Config:Set("enableAOE", state.profileSettings.enableAOE)
    WR.Config:Set("enableDungeonAwareness", state.profileSettings.enableDungeonAwareness)
    WR.Config:Set("saveResourcesForBurst", state.profileSettings.saveResourcesForBurst)
    WR.Config:Set("autoSwitchTargets", state.profileSettings.autoSwitchTargets)
    WR.Config:Set("rotationSpeed", state.profileSettings.rotationSpeed)
    
    -- Apply UI settings
    if WR.UI then
        WR.UI:ApplySettings(state.profileSettings.UI)
    end
    
    -- Apply class-specific settings
    local playerClass = select(2, UnitClass("player"))
    if state.profileSettings.classSpecific and WR.Classes and WR.Classes[playerClass] then
        -- Pass class-specific settings to the class module
        for key, value in pairs(state.profileSettings.classSpecific) do
            if WR.Classes[playerClass].SetSetting then
                WR.Classes[playerClass]:SetSetting(key, value)
            end
        end
    end
    
    -- Apply dungeon settings
    if WR.DungeonIntelligence then
        WR.DungeonIntelligence:SetEnabled(state.profileSettings.enableDungeonAwareness)
        
        if state.profileSettings.dungeonAwarenessLevel then
            WR.DungeonIntelligence:SetFeatureEnabled("targetPriority", state.profileSettings.dungeonAwarenessLevel >= 2)
            WR.DungeonIntelligence:SetFeatureEnabled("interruptPriority", state.profileSettings.dungeonAwarenessLevel >= 1)
            WR.DungeonIntelligence:SetFeatureEnabled("dispelPriority", state.profileSettings.dungeonAwarenessLevel >= 2)
            WR.DungeonIntelligence:SetFeatureEnabled("avoidance", state.profileSettings.dungeonAwarenessLevel >= 3)
            WR.DungeonIntelligence:SetFeatureEnabled("patrolWarning", state.profileSettings.dungeonAwarenessLevel >= 4)
            WR.DungeonIntelligence:SetFeatureEnabled("tacticalAdvice", state.profileSettings.dungeonAwarenessLevel >= 5)
        end
    end
    
    WR:Debug("Applied profile settings from:", state.currentProfile)
    return true
end

-- Update a specific profile setting
function ProfileManager:UpdateSetting(key, value, section)
    if not key then
        WR:Debug("Invalid setting key")
        return false
    end
    
    -- Update in different sections
    if section == "UI" then
        if not state.profileSettings.UI then
            state.profileSettings.UI = {}
        end
        state.profileSettings.UI[key] = value
    elseif section == "classSpecific" then
        if not state.profileSettings.classSpecific then
            state.profileSettings.classSpecific = {}
        end
        state.profileSettings.classSpecific[key] = value
    else
        -- Update in main settings
        state.profileSettings[key] = value
    end
    
    -- Apply the changed setting
    if section == "UI" and WR.UI then
        local settings = {}
        settings[key] = value
        WR.UI:ApplySettings(settings)
    elseif section == "classSpecific" then
        local playerClass = select(2, UnitClass("player"))
        if WR.Classes and WR.Classes[playerClass] and WR.Classes[playerClass].SetSetting then
            WR.Classes[playerClass]:SetSetting(key, value)
        end
    else
        WR.Config:Set(key, value)
    end
    
    -- Mark as having unsaved changes
    state.unsavedChanges = true
    
    -- Autosave if enabled
    if state.autosaveEnabled then
        self:SaveCurrentProfile()
    end
    
    WR:Debug("Updated setting:", key, "=", value, section and ("in " .. section) or "")
    return true
end

-- Get all profiles
function ProfileManager:GetProfiles()
    local profiles = {}
    
    -- Include saved profiles
    for name, _ in pairs(state.classProfiles) do
        local metadata = state.profileMetadata[name] or {
            description = "Custom profile",
            class = select(2, UnitClass("player")),
            spec = nil,
            author = "Player",
            isPreset = false,
            lastUpdate = 0
        }
        
        table.insert(profiles, {
            name = name,
            description = metadata.description,
            class = metadata.class,
            spec = metadata.spec,
            author = metadata.author,
            isPreset = metadata.isPreset,
            lastUpdate = metadata.lastUpdate,
            isCurrent = (name == state.currentProfile)
        })
    end
    
    -- Include available presets not already saved
    for name, preset in pairs(state.presetProfiles) do
        if not state.classProfiles[name] then
            table.insert(profiles, {
                name = name,
                description = preset.description,
                class = preset.class,
                spec = preset.spec,
                author = preset.author,
                isPreset = true,
                lastUpdate = 0,
                isCurrent = false
            })
        end
    end
    
    return profiles
end

-- Get the current profile name
function ProfileManager:GetCurrentProfile()
    return state.currentProfile
end

-- Get a specific profile setting
function ProfileManager:GetSetting(key, section)
    if not key then
        WR:Debug("Invalid setting key")
        return nil
    end
    
    if section == "UI" then
        if not state.profileSettings.UI then
            return nil
        end
        return state.profileSettings.UI[key]
    elseif section == "classSpecific" then
        if not state.profileSettings.classSpecific then
            return nil
        end
        return state.profileSettings.classSpecific[key]
    else
        -- Get from main settings
        return state.profileSettings[key]
    end
end

-- Get all settings from current profile
function ProfileManager:GetAllSettings()
    return self:CopyTable(state.profileSettings)
end

-- Reset current profile to defaults
function ProfileManager:ResetCurrentProfile()
    -- Store default settings to current profile
    state.profileSettings = self:CopyTable(state.defaultSettings)
    
    -- Apply settings
    self:ApplyProfileSettings()
    
    -- Save changes
    self:SaveCurrentProfile()
    
    WR:Debug("Reset profile to defaults:", state.currentProfile)
    return true
end

-- Import a profile from a string
function ProfileManager:ImportProfile(profileStr, name)
    if not profileStr or profileStr == "" then
        WR:Debug("Invalid profile string")
        return false
    end
    
    -- Try to deserialize the profile
    local success, profileData = self:DeserializeProfile(profileStr)
    if not success then
        WR:Debug("Failed to deserialize profile")
        return false
    end
    
    -- Name validation
    if not name or name == "" then
        name = profileData.name or "Imported Profile"
    end
    
    -- Check if compatible with current class
    local playerClass = select(2, UnitClass("player"))
    if profileData.class and profileData.class ~= playerClass then
        WR:Debug("Profile is not compatible with current class")
        return false
    end
    
    -- Create profile with the imported settings
    self:CreateProfile(name, profileData.settings)
    
    -- Import metadata
    if profileData.metadata then
        state.profileMetadata[name] = profileData.metadata
        state.profileMetadata[name].lastUpdate = time()
    end
    
    -- Load the new profile
    self:LoadProfile(name)
    
    WR:Debug("Imported profile as:", name)
    return true
end

-- Export a profile to a string
function ProfileManager:ExportProfile(name)
    name = name or state.currentProfile
    
    if not name or not state.classProfiles[name] then
        WR:Debug("Invalid profile name")
        return nil
    end
    
    -- Create export data structure
    local exportData = {
        name = name,
        class = select(2, UnitClass("player")),
        spec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil,
        settings = state.classProfiles[name],
        metadata = state.profileMetadata[name] or {
            description = "Custom profile",
            class = select(2, UnitClass("player")),
            spec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil,
            author = "Player",
            isPreset = false,
            lastUpdate = time()
        },
        exportVersion = 1,
        exportTime = time()
    }
    
    -- Serialize to string
    local exportStr = self:SerializeProfile(exportData)
    
    WR:Debug("Exported profile:", name)
    return exportStr
end

-- Serialize profile to string
function ProfileManager:SerializeProfile(profileData)
    -- Simple serialization to string
    -- In a real addon, this would use proper serialization like AceSerializer
    return WR:TableToString(profileData)
end

-- Deserialize profile from string
function ProfileManager:DeserializeProfile(profileStr)
    -- Simple deserialization from string
    -- In a real addon, this would use proper deserialization like AceSerializer
    local success, profileData = pcall(function() return WR:StringToTable(profileStr) end)
    return success, profileData
end

-- Enable/disable autosave
function ProfileManager:SetAutosave(enabled)
    state.autosaveEnabled = enabled
    
    WR:Debug("Autosave", enabled and "enabled" or "disabled")
    return true
end

-- Check if there are unsaved changes
function ProfileManager:HasUnsavedChanges()
    return state.unsavedChanges
end

-- Get recently used profiles
function ProfileManager:GetRecentProfiles()
    -- Sort by most recent first
    local sorted = self:CopyTable(state.profileHistory)
    table.sort(sorted, function(a, b) return a.time > b.time end)
    
    local result = {}
    local added = {}
    
    -- Deduplicate
    for _, entry in ipairs(sorted) do
        if not added[entry.name] and state.classProfiles[entry.name] then
            table.insert(result, entry.name)
            added[entry.name] = true
        end
    end
    
    return result
end

-- Create a new profile from current class/spec
function ProfileManager:CreateProfileFromCurrentSpec()
    local playerClass = select(2, UnitClass("player"))
    local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil
    local specName = specID and select(2, GetSpecializationInfoByID(specID)) or "Unknown"
    
    local name = playerClass .. ": " .. specName
    
    -- Ensure unique name
    local counter = 1
    local baseName = name
    while state.classProfiles[name] do
        counter = counter + 1
        name = baseName .. " " .. counter
    end
    
    -- Get class-specific settings from class module
    local classSettings = {}
    if WR.Classes and WR.Classes[playerClass] then
        -- Ideally the class module would export its current settings
        -- For now, we'll just use default class-specific settings
        classSettings = {
            classSpecific = {}
        }
    end
    
    -- Create the profile
    self:CreateProfile(name, classSettings)
    
    -- Load the new profile
    self:LoadProfile(name)
    
    WR:Debug("Created profile from current spec:", name)
    return name
end

-- Utility function: Deep copy a table
function ProfileManager:CopyTable(tbl)
    if type(tbl) ~= "table" then return tbl end
    
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:CopyTable(v)
        else
            copy[k] = v
        end
    end
    
    return copy
end

-- Utility function: Merge settings tables
function ProfileManager:MergeSettings(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then return target end
    
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            self:MergeSettings(target[k], v)
        else
            target[k] = v
        end
    end
    
    return target
end

-- Get compatible presets for current class/spec
function ProfileManager:GetCompatiblePresets()
    local result = {}
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil
    
    for name, preset in pairs(state.presetProfiles) do
        if preset.class == playerClass and (not preset.spec or preset.spec == playerSpec) then
            table.insert(result, {
                name = name,
                description = preset.description,
                author = preset.author
            })
        end
    end
    
    return result
end

-- Initialize the module
ProfileManager:Initialize()

return ProfileManager