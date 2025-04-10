local addonName, WR = ...

-- ProfileManager module to handle player profiles and settings
local ProfileManager = {}
WR.ProfileManager = ProfileManager

-- Default profile template
local DEFAULT_PROFILE = {
    version = 1,
    created = time(),
    lastModified = time(),
    name = "Default",
    settings = {
        general = {
            enabled = true,
            autoSwapInCombat = true,
            autoEnableInDungeons = true,
            autoEnableInRaids = true,
            showMinimap = true,
            debugMode = false,
            useSmartTargeting = true,
            throttleRate = 0.1,
            combatOnly = true
        },
        rotation = {
            useAOERotation = true,
            aoeThreshold = 3,
            interrupt = {
                enabled = true,
                priorityOnly = false,
                delay = 0.3,
                randomDelay = true,
                minDelay = 0.1,
                maxDelay = 0.5
            },
            defensives = {
                enabled = true,
                autoUseHealthstone = true,
                healthstoneThreshold = 30,
                autoCancelChanneling = true
            },
            bursting = {
                enabled = true,
                useTrinkets = true,
                useRacials = true,
                saveForBosses = false
            }
        },
        class = {}, -- Class-specific settings populated per class
        dungeons = {
            useDungeonIntelligence = true,
            priorityInterrupts = true,
            autoTargetPriority = true,
            optimizePulls = true,
            adaptToAffixes = true
        },
        ui = {
            scale = 1.0,
            opacity = 0.9,
            position = {
                x = 0,
                y = 0,
                point = "CENTER",
                relativeTo = "UIParent",
                relativePoint = "CENTER"
            },
            locked = false,
            showAllModes = false,
            textColor = {r = 1, g = 1, b = 1, a = 1},
            backgroundColor = {r = 0, g = 0, b = 0, a = 0.7},
            borderColor = {r = 0.5, g = 0.5, b = 0.5, a = 1}
        }
    },
    classProfiles = {} -- Populated with class-specific profiles at runtime
}

-- Storage for loaded profiles
ProfileManager.profiles = {}
ProfileManager.currentProfile = nil
ProfileManager.activeProfile = nil

-- Initialize the module
function ProfileManager:Initialize()
    -- Create and initialize DB if not exists
    self:InitializeDB()
    
    -- Load the default profile for the current class if available
    self:LoadDefaultProfileForClass()
    
    WR:Debug("ProfileManager module initialized")
end

-- Initialize the database and create default profiles if needed
function ProfileManager:InitializeDB()
    -- Ensure the SavedVariables table exists
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.profiles = WindrunnerRotationsDB.profiles or {}
    WindrunnerRotationsDB.characterProfiles = WindrunnerRotationsDB.characterProfiles or {}
    
    local playerName = UnitName("player")
    local realm = GetRealmName()
    local fullName = playerName .. "-" .. realm
    
    -- Create character entry if needed
    WindrunnerRotationsDB.characterProfiles[fullName] = WindrunnerRotationsDB.characterProfiles[fullName] or {}
    
    -- Create default profile if none exists
    if not next(WindrunnerRotationsDB.profiles) then
        self:CreateDefaultProfiles()
    end
    
    -- Store reference to profiles
    self.profiles = WindrunnerRotationsDB.profiles
end

-- Create default profiles for all classes
function ProfileManager:CreateDefaultProfiles()
    local defaultClasses = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", 
        "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", 
        "DRUID", "DEMONHUNTER", "EVOKER"
    }
    
    -- Create a global Default profile
    local defaultProfile = self:CloneTable(DEFAULT_PROFILE)
    defaultProfile.id = "default"
    WindrunnerRotationsDB.profiles["default"] = defaultProfile
    
    -- Create default profile for each class
    for _, class in ipairs(defaultClasses) do
        local classProfile = self:CloneTable(DEFAULT_PROFILE)
        classProfile.id = "default_" .. class
        classProfile.name = "Default " .. class
        classProfile.class = class
        
        -- Add class-specific settings
        self:AddClassSpecificSettings(classProfile, class)
        
        -- Add spec profiles for the class
        self:AddSpecProfiles(classProfile, class)
        
        -- Save the profile
        WindrunnerRotationsDB.profiles["default_" .. class] = classProfile
    end
    
    WR:Debug("Created default profiles for all classes")
end

-- Add class-specific settings to a profile
function ProfileManager:AddClassSpecificSettings(profile, class)
    -- Initialize class settings
    profile.settings.class = {}
    
    -- Add general class settings
    if class == "WARRIOR" then
        profile.settings.class.useCharge = true
        profile.settings.class.useHeroicLeap = true
        profile.settings.class.prioritizeRage = true
    elseif class == "PALADIN" then
        profile.settings.class.useBlessing = true
        profile.settings.class.prioritizeHolyPower = true
        profile.settings.class.useLayOnHands = true
    elseif class == "HUNTER" then
        profile.settings.class.autoPetSummon = true
        profile.settings.class.autoPetMend = true
        profile.settings.class.useMisdirection = true
    elseif class == "ROGUE" then
        profile.settings.class.usePoisons = true
        profile.settings.class.useVanish = true
        profile.settings.class.useTricksOfTrade = true
    elseif class == "PRIEST" then
        profile.settings.class.useDesperatePrayer = true
        profile.settings.class.useFade = true
        profile.settings.class.useLeapOfFaith = false
    elseif class == "DEATHKNIGHT" then
        profile.settings.class.useDeathGrip = true
        profile.settings.class.useRaiseAlly = true
        profile.settings.class.prioritizeRunicPower = true
    elseif class == "SHAMAN" then
        profile.settings.class.useEarthShield = true
        profile.settings.class.useElementals = true
        profile.settings.class.prioritizeManaTotems = true
    elseif class == "MAGE" then
        profile.settings.class.useIceBlock = true
        profile.settings.class.useColdSnap = true
        profile.settings.class.prioritizeProcs = true
    elseif class == "WARLOCK" then
        profile.settings.class.autoPetSummon = true
        profile.settings.class.useHealthFunnel = true
        profile.settings.class.useSoulstone = true
    elseif class == "MONK" then
        profile.settings.class.useTouchOfKarma = true
        profile.settings.class.useZen = true
        profile.settings.class.prioritizeChi = true
    elseif class == "DRUID" then
        profile.settings.class.useShapeshiftTravel = true
        profile.settings.class.useRebirth = true
        profile.settings.class.prioritizeEclipse = true
    elseif class == "DEMONHUNTER" then
        profile.settings.class.useChaosNova = true
        profile.settings.class.useGlide = true
        profile.settings.class.prioritizeFury = true
    elseif class == "EVOKER" then
        profile.settings.class.useHover = true
        profile.settings.class.useCauterizingFlame = true
        profile.settings.class.prioritizeEssence = true
    end
    
    -- Add more complex class settings based on advanced mechanics
    self:AddAdvancedClassSettings(profile, class)
end

-- Add advanced class settings
function ProfileManager:AddAdvancedClassSettings(profile, class)
    -- Add settings for advanced class mechanics
    if class == "WARRIOR" then
        profile.settings.class.advanced = {
            useVictoryRush = true,
            rageDumpThreshold = 80,
            enrageUptime = true,
            shieldBlockUptime = true
        }
    elseif class == "PALADIN" then
        profile.settings.class.advanced = {
            adaptAuraMastery = true,
            divineShieldCancel = true,
            consecrationUptime = true,
            avengingWrathOptimal = true
        }
    elseif class == "HUNTER" then
        profile.settings.class.advanced = {
            aspectOfTheWild = true,
            killCommandPriority = true,
            barbedShotUptime = true,
            wildMarksOptimal = true
        }
    elseif class == "ROGUE" then
        profile.settings.class.advanced = {
            sliceAndDiceUptime = true,
            rollTheBonesOptimal = true,
            shadowDanceOptimal = true,
            ruptureUptime = true
        }
    elseif class == "PRIEST" then
        profile.settings.class.advanced = {
            powerWordShieldRotation = true,
            mindBlastOnCD = true,
            voidformOptimal = true,
            spiritShellOptimal = true
        }
    elseif class == "DEATHKNIGHT" then
        profile.settings.class.advanced = {
            runeEfficiency = true,
            diseaseUptime = true,
            breathOptimal = true,
            armyOptimal = true
        }
    elseif class == "SHAMAN" then
        profile.settings.class.advanced = {
            flameShockUptime = true,
            lavaBurstOptimal = true,
            maelstromEfficiency = true,
            ascendanceOptimal = true
        }
    elseif class == "MAGE" then
        profile.settings.class.advanced = {
            arcaneChargesBalance = true,
            hotStreakOptimal = true,
            iciclesOptimal = true,
            manaGemEfficiency = true
        }
    elseif class == "WARLOCK" then
        profile.settings.class.advanced = {
            dotUptime = true,
            shardEfficiency = true,
            darkglareOptimal = true,
            tyrantOptimal = true
        }
    elseif class == "MONK" then
        profile.settings.class.advanced = {
            blackoutComboOptimal = true,
            tigerPalmEfficiency = true,
            celestialAlignmentOptimal = true,
            risingSunKickOptimal = true
        }
    elseif class == "DRUID" then
        profile.settings.class.advanced = {
            eclipseOptimal = true,
            ironfurUptime = true,
            savageRoarUptime = true,
            lifebloomUptime = true
        }
    elseif class == "DEMONHUNTER" then
        profile.settings.class.advanced = {
            eyeBeamEfficiency = true,
            metamorphosisOptimal = true,
            demonSpikeUptime = true,
            soulFragmentsTracker = true
        }
    elseif class == "EVOKER" then
        profile.settings.class.advanced = {
            empowerManagement = true,
            dragonrageOptimal = true,
            livingFlameEfficiency = true,
            essenceManagement = true
        }
    end
end

-- Add spec profiles for a class
function ProfileManager:AddSpecProfiles(profile, class)
    profile.classProfiles = {}
    
    -- Get the specs for this class
    local specs = self:GetSpecsForClass(class)
    
    -- Create a profile for each spec
    for specID, specName in pairs(specs) do
        local specProfile = {
            name = specName,
            specID = specID,
            enabled = true,
            settings = {
                general = {
                    priorityTargeting = true,
                    aoeThreshold = 3,
                    burstMode = "auto" -- auto, manual, boss, encounter
                },
                rotationSettings = {}, -- Populated with spec-specific rotation settings
                talents = {} -- Populated with talent build recommendations if enabled
            }
        }
        
        -- Add spec-specific rotation settings
        self:AddSpecRotationSettings(specProfile, class, specID)
        
        -- Add the spec profile
        profile.classProfiles[specID] = specProfile
    end
end

-- Get the specs for a class
function ProfileManager:GetSpecsForClass(class)
    local specs = {}
    
    if class == "WARRIOR" then
        specs[71] = "Arms"
        specs[72] = "Fury"
        specs[73] = "Protection"
    elseif class == "PALADIN" then
        specs[65] = "Holy"
        specs[66] = "Protection"
        specs[70] = "Retribution"
    elseif class == "HUNTER" then
        specs[253] = "Beast Mastery"
        specs[254] = "Marksmanship"
        specs[255] = "Survival"
    elseif class == "ROGUE" then
        specs[259] = "Assassination"
        specs[260] = "Outlaw"
        specs[261] = "Subtlety"
    elseif class == "PRIEST" then
        specs[256] = "Discipline"
        specs[257] = "Holy"
        specs[258] = "Shadow"
    elseif class == "DEATHKNIGHT" then
        specs[250] = "Blood"
        specs[251] = "Frost"
        specs[252] = "Unholy"
    elseif class == "SHAMAN" then
        specs[262] = "Elemental"
        specs[263] = "Enhancement"
        specs[264] = "Restoration"
    elseif class == "MAGE" then
        specs[62] = "Arcane"
        specs[63] = "Fire"
        specs[64] = "Frost"
    elseif class == "WARLOCK" then
        specs[265] = "Affliction"
        specs[266] = "Demonology"
        specs[267] = "Destruction"
    elseif class == "MONK" then
        specs[268] = "Brewmaster"
        specs[269] = "Windwalker"
        specs[270] = "Mistweaver"
    elseif class == "DRUID" then
        specs[102] = "Balance"
        specs[103] = "Feral"
        specs[104] = "Guardian"
        specs[105] = "Restoration"
    elseif class == "DEMONHUNTER" then
        specs[577] = "Havoc"
        specs[581] = "Vengeance"
    elseif class == "EVOKER" then
        specs[1467] = "Devastation"
        specs[1468] = "Preservation"
        specs[1473] = "Augmentation"
    end
    
    return specs
end

-- Add spec-specific rotation settings
function ProfileManager:AddSpecRotationSettings(specProfile, class, specID)
    -- Initialize rotation settings
    specProfile.settings.rotationSettings = {
        prioritizeDefensives = false,
        prioritizeMovement = false,
        prioritizeInterrupts = true,
        useDefaultRotation = true,
        customRotation = false,
        customRotationRules = {},
        optimizeSingleTarget = true,
        optimizeAoE = true,
        optimizeCleave = true,
        adaptToEncounter = true
    }
    
    -- Add spec-specific settings based on role
    local role = self:GetRoleForSpec(class, specID)
    
    if role == "TANK" then
        specProfile.settings.rotationSettings.prioritizeDefensives = true
        specProfile.settings.rotationSettings.threatGeneration = true
        specProfile.settings.rotationSettings.activeMitigation = true
        specProfile.settings.rotationSettings.defensiveCooldowns = "intelligent" -- intelligent, manual, automatic
    elseif role == "HEALER" then
        specProfile.settings.rotationSettings.healingMode = "intelligent" -- intelligent, efficiency, throughput
        specProfile.settings.rotationSettings.prioritizeDispels = true
        specProfile.settings.rotationSettings.manaEfficiency = true
        specProfile.settings.rotationSettings.damageWhenHealing = false
    elseif role == "DAMAGER" then
        specProfile.settings.rotationSettings.damagePriority = "single" -- single, cleave, aoe
        specProfile.settings.rotationSettings.resourceEfficiency = true
        specProfile.settings.rotationSettings.cooldownUsage = "intelligent" -- intelligent, manual, on cooldown
        specProfile.settings.rotationSettings.adaptToPhases = true
    end
    
    -- Add further spec-specific settings
    if class == "WARRIOR" then
        if specID == 71 then -- Arms
            specProfile.settings.rotationSettings.mortalStrikePriority = true
            specProfile.settings.rotationSettings.executePhase = true
            specProfile.settings.rotationSettings.colossusSmashWindow = true
        elseif specID == 72 then -- Fury
            specProfile.settings.rotationSettings.enrageUptime = true
            specProfile.settings.rotationSettings.rampagePriority = true
            specProfile.settings.rotationSettings.executePhase = true
        elseif specID == 73 then -- Protection
            specProfile.settings.rotationSettings.shieldBlockUptime = true
            specProfile.settings.rotationSettings.ignorePainEfficiency = true
            specProfile.settings.rotationSettings.revengeOptimization = true
        end
    elseif class == "PALADIN" then
        if specID == 65 then -- Holy
            specProfile.settings.rotationSettings.holyShockPriority = true
            specProfile.settings.rotationSettings.lightOfDawnOptimal = true
            specProfile.settings.rotationSettings.beaconUptime = true
        elseif specID == 66 then -- Protection
            specProfile.settings.rotationSettings.shieldOfRighteousUptime = true
            specProfile.settings.rotationSettings.consecrationUptime = true
            specProfile.settings.rotationSettings.hammerOfWrath = true
        elseif specID == 70 then -- Retribution
            specProfile.settings.rotationSettings.judgmentWindow = true
            specProfile.settings.rotationSettings.divineStormPriority = true
            specProfile.settings.rotationSettings.executionesSentence = true
        end
    elseif class == "HUNTER" then
        if specID == 253 then -- Beast Mastery
            specProfile.settings.rotationSettings.barbedShotUptime = true
            specProfile.settings.rotationSettings.beastCleavePriority = true
            specProfile.settings.rotationSettings.aspectOfTheWild = true
        elseif specID == 254 then -- Marksmanship
            specProfile.settings.rotationSettings.aimedShotPriority = true
            specProfile.settings.rotationSettings.preciseShots = true
            specProfile.settings.rotationSettings.trickShotsWindow = true
        elseif specID == 255 then -- Survival
            specProfile.settings.rotationSettings.wildfirebombPriority = true
            specProfile.settings.rotationSettings.coordinatedAssault = true
            specProfile.settings.rotationSettings.mongooseBite = true
        end
    end
    
    -- Continue for other classes and their specs...
    -- For brevity, only warrior, paladin, and hunter examples are shown
    
    -- Additional optimization settings can be added as needed for each spec
end

-- Get the role for a spec
function ProfileManager:GetRoleForSpec(class, specID)
    -- Tank specs
    if (class == "WARRIOR" and specID == 73) or
       (class == "PALADIN" and specID == 66) or
       (class == "DEATHKNIGHT" and specID == 250) or
       (class == "MONK" and specID == 268) or
       (class == "DRUID" and specID == 104) or
       (class == "DEMONHUNTER" and specID == 581) then
        return "TANK"
    -- Healer specs
    elseif (class == "PALADIN" and specID == 65) or
           (class == "PRIEST" and (specID == 256 or specID == 257)) or
           (class == "SHAMAN" and specID == 264) or
           (class == "MONK" and specID == 270) or
           (class == "DRUID" and specID == 105) or
           (class == "EVOKER" and specID == 1468) then
        return "HEALER"
    -- All other specs are DPS
    else
        return "DAMAGER"
    end
end

-- Load the default profile for the current player's class
function ProfileManager:LoadDefaultProfileForClass()
    local _, class = UnitClass("player")
    local profileKey = "default_" .. class
    
    if self.profiles[profileKey] then
        self.currentProfile = profileKey
        self.activeProfile = self:CloneTable(self.profiles[profileKey])
        WR:Debug("Loaded default profile for", class)
    else
        -- Fallback to global default
        self.currentProfile = "default"
        self.activeProfile = self:CloneTable(self.profiles["default"])
        WR:Debug("Loaded global default profile")
    end
    
    -- Apply the profile
    self:ApplyProfile(self.activeProfile)
end

-- Apply a profile's settings to the addon
function ProfileManager:ApplyProfile(profile)
    if not profile then return end
    
    -- Apply general settings
    WR.Settings = WR.Settings or {}
    WR.Settings.general = self:CloneTable(profile.settings.general)
    WR.Settings.rotation = self:CloneTable(profile.settings.rotation)
    WR.Settings.class = self:CloneTable(profile.settings.class)
    WR.Settings.dungeons = self:CloneTable(profile.settings.dungeons)
    WR.Settings.ui = self:CloneTable(profile.settings.ui)
    
    -- Apply class/spec specific settings if available
    local _, class = UnitClass("player")
    if class == profile.class then
        local specID = GetSpecialization() and GetSpecializationInfo(GetSpecialization()) or nil
        
        if specID and profile.classProfiles and profile.classProfiles[specID] then
            WR.Settings.spec = self:CloneTable(profile.classProfiles[specID].settings)
            WR:Debug("Applied spec-specific settings for", profile.classProfiles[specID].name)
        else
            WR.Settings.spec = {}
            WR:Debug("No spec-specific settings found")
        end
    else
        WR.Settings.spec = {}
        WR:Debug("Profile is for a different class")
    end
    
    -- Signal that settings have changed
    self:TriggerSettingsChanged()
end

-- Create a new profile
function ProfileManager:CreateProfile(name, copyFrom)
    if not name or name == "" then
        name = "New Profile " .. os.date("%Y-%m-%d %H:%M:%S")
    end
    
    local sourceProfile
    if copyFrom and self.profiles[copyFrom] then
        sourceProfile = self.profiles[copyFrom]
    else
        -- Use current active profile as source
        sourceProfile = self.activeProfile
    end
    
    -- Create new profile
    local newProfile = self:CloneTable(sourceProfile)
    newProfile.id = "profile_" .. time() .. "_" .. math.random(1000, 9999)
    newProfile.name = name
    newProfile.created = time()
    newProfile.lastModified = time()
    
    -- Save to DB
    self.profiles[newProfile.id] = newProfile
    WindrunnerRotationsDB.profiles[newProfile.id] = newProfile
    
    WR:Debug("Created new profile:", name)
    return newProfile.id
end

-- Delete a profile
function ProfileManager:DeleteProfile(profileID)
    if not profileID or not self.profiles[profileID] then return false end
    
    -- Don't allow deleting default profiles
    if profileID == "default" or profileID:match("^default_") then
        WR:Debug("Cannot delete default profiles")
        return false
    end
    
    -- Remove from DB
    self.profiles[profileID] = nil
    WindrunnerRotationsDB.profiles[profileID] = nil
    
    -- If this was the active profile, load the default
    if self.currentProfile == profileID then
        self:LoadDefaultProfileForClass()
    end
    
    WR:Debug("Deleted profile:", profileID)
    return true
end

-- Switch to a different profile
function ProfileManager:SwitchProfile(profileID)
    if not profileID or not self.profiles[profileID] then return false end
    
    -- Load the profile
    self.currentProfile = profileID
    self.activeProfile = self:CloneTable(self.profiles[profileID])
    
    -- Apply the profile
    self:ApplyProfile(self.activeProfile)
    
    -- Update character's saved profile
    local playerName = UnitName("player")
    local realm = GetRealmName()
    local fullName = playerName .. "-" .. realm
    
    WindrunnerRotationsDB.characterProfiles[fullName].profile = profileID
    
    WR:Debug("Switched to profile:", self.profiles[profileID].name)
    return true
end

-- Save current profile changes
function ProfileManager:SaveProfile()
    if not self.currentProfile or not self.activeProfile then return false end
    
    -- Update last modified
    self.activeProfile.lastModified = time()
    
    -- Save to DB
    self.profiles[self.currentProfile] = self:CloneTable(self.activeProfile)
    WindrunnerRotationsDB.profiles[self.currentProfile] = self:CloneTable(self.activeProfile)
    
    WR:Debug("Saved profile changes:", self.activeProfile.name)
    return true
end

-- Export a profile to string
function ProfileManager:ExportProfile(profileID)
    if not profileID then profileID = self.currentProfile end
    if not profileID or not self.profiles[profileID] then return nil end
    
    -- Clone the profile to remove any functions or other non-serializable data
    local exportProfile = self:CloneTable(self.profiles[profileID])
    
    -- Add export metadata
    exportProfile.exportVersion = 1
    exportProfile.exportDate = time()
    
    -- Convert to string (using LibSerialize or similar would be ideal)
    local serialized = self:Serialize(exportProfile)
    -- Compress and encode for sharing
    local encoded = self:EncodeForExport(serialized)
    
    WR:Debug("Exported profile:", exportProfile.name)
    return encoded
end

-- Import a profile from string
function ProfileManager:ImportProfile(importString)
    if not importString or importString == "" then return false, "Empty import string" end
    
    -- Decode and decompress
    local serialized = self:DecodeFromImport(importString)
    if not serialized then return false, "Invalid import format" end
    
    -- Deserialize
    local success, importProfile = self:Deserialize(serialized)
    if not success or not importProfile then return false, "Failed to deserialize profile" end
    
    -- Validate the imported profile
    if not importProfile.name or not importProfile.settings then
        return false, "Invalid profile structure"
    end
    
    -- Create a new unique ID for the imported profile
    importProfile.id = "imported_" .. time() .. "_" .. math.random(1000, 9999)
    importProfile.name = importProfile.name .. " (Imported)"
    importProfile.imported = time()
    
    -- Save to DB
    self.profiles[importProfile.id] = importProfile
    WindrunnerRotationsDB.profiles[importProfile.id] = importProfile
    
    WR:Debug("Imported profile:", importProfile.name)
    return true, importProfile.id
end

-- Very simple serialization for demonstration
-- In a real addon, use a proper serialization library like LibSerialize
function ProfileManager:Serialize(data)
    -- Simple approach for demo: convert to a string representation
    -- This is not a proper implementation - just a placeholder
    return table.concat({"WR_PROFILE", self:TableToString(data)}, ":")
end

-- Very simple deserialization for demonstration
function ProfileManager:Deserialize(serialized)
    -- Simple approach for demo: parse string representation back to table
    -- This is not a proper implementation - just a placeholder
    local prefix, dataString = strsplit(":", serialized, 2)
    if prefix ~= "WR_PROFILE" then
        return false, nil
    end
    
    return true, self:StringToTable(dataString)
end

-- Encode for export (compression + Base64 encoding)
function ProfileManager:EncodeForExport(serialized)
    -- Placeholder for proper implementation
    -- In a real addon, compress with LibDeflate and encode with Base64 or similar
    return serialized -- Just return as-is for demonstration
end

-- Decode from import string
function ProfileManager:DecodeFromImport(importString)
    -- Placeholder for proper implementation
    -- In a real addon, decode from Base64 and decompress
    return importString -- Just return as-is for demonstration
end

-- Very simple table to string conversion
function ProfileManager:TableToString(tbl)
    -- This is an extremely simplified placeholder for demonstration purposes
    -- In a real addon, use a proper serialization library
    return tostring(tbl)
end

-- Very simple string to table conversion
function ProfileManager:StringToTable(str)
    -- This is an extremely simplified placeholder for demonstration purposes
    -- In a real addon, use a proper serialization library
    return {}
end

-- Get a list of all profiles
function ProfileManager:GetProfileList()
    local list = {}
    
    for id, profile in pairs(self.profiles) do
        table.insert(list, {
            id = id,
            name = profile.name,
            class = profile.class,
            created = profile.created,
            lastModified = profile.lastModified
        })
    end
    
    return list
end

-- Get a specific profile by ID
function ProfileManager:GetProfile(profileID)
    if not profileID then return nil end
    return self.profiles[profileID]
end

-- Get the current active profile
function ProfileManager:GetActiveProfile()
    return self.activeProfile
end

-- Update a setting in the active profile
function ProfileManager:UpdateSetting(path, value)
    if not path or not self.activeProfile then return false end
    
    -- Parse the path into components
    local components = {}
    for component in string.gmatch(path, "([^%.]+)") do
        table.insert(components, component)
    end
    
    -- Navigate to the target setting
    local current = self.activeProfile.settings
    for i = 1, #components - 1 do
        local component = components[i]
        if not current[component] then
            current[component] = {}
        end
        current = current[component]
    end
    
    -- Update the value
    current[components[#components]] = value
    
    -- Update last modified
    self.activeProfile.lastModified = time()
    
    -- Apply the change
    self:ApplyProfile(self.activeProfile)
    
    return true
end

-- Trigger an event notifying that settings have changed
function ProfileManager:TriggerSettingsChanged()
    -- Signal to other modules that settings have changed
    if WR.Events then
        WR.Events:TriggerEvent("SETTINGS_CHANGED")
    end
end

-- Clone a table deeply
function ProfileManager:CloneTable(src)
    if type(src) ~= "table" then return src end
    
    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = self:CloneTable(v)
        else
            dest[k] = v
        end
    end
    
    return dest
end

-- Initialize the module
ProfileManager:Initialize()

return ProfileManager