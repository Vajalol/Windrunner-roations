-- PetManager.lua
-- Handles automatic pet management (summon, control, abilities)
local addonName, WR = ...
local PetManager = {}
WR.PetManager = PetManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local enablePetManagement = true
local lastPetAbilityTime = 0
local lastPetSummonCheck = 0
local MIN_PET_ABILITY_INTERVAL = 0.5  -- Minimum seconds between pet abilities
local PET_SUMMON_CHECK_INTERVAL = 10.0  -- Check for pet every 10 seconds
local currentPetGUID = nil
local petAbilities = {}
local petStates = {}

-- Pet configurations by class/spec
local petConfigurations = {
    ["HUNTER"] = {
        -- Beast Mastery spec (1)
        [1] = {
            summonAbilities = {
                { id = 883, name = "Call Pet 1" },
                { id = 83242, name = "Call Pet 2" },
                { id = 83243, name = "Call Pet 3" },
                { id = 83244, name = "Call Pet 4" },
                { id = 83245, name = "Call Pet 5" }
            },
            reviveAbilities = {
                { id = 982, name = "Revive Pet" }
            },
            modeAbilities = {
                { id = 34477, name = "Misdirection", target = "tank" },
                { id = 193530, name = "Aspect of the Wild" },
                { id = 19574, name = "Bestial Wrath" },
                { id = 217200, name = "Barbed Shot" }
            },
            petAbilities = {
                { id = 272790, name = "Frenzy", isAura = true },
                { id = 272790, name = "Frenzy", isAura = true }
            },
            defaultMode = "assist",
            needsStanceControl = true
        },
        -- Marksmanship spec (2)
        [2] = {
            summonAbilities = {
                { id = 883, name = "Call Pet 1" },
                { id = 83242, name = "Call Pet 2" },
                { id = 83243, name = "Call Pet 3" },
                { id = 83244, name = "Call Pet 4" },
                { id = 83245, name = "Call Pet 5" }
            },
            reviveAbilities = {
                { id = 982, name = "Revive Pet" }
            },
            modeAbilities = {
                { id = 34477, name = "Misdirection", target = "tank" }
            },
            defaultMode = "assist",
            needsStanceControl = true
        },
        -- Survival spec (3)
        [3] = {
            summonAbilities = {
                { id = 883, name = "Call Pet 1" },
                { id = 83242, name = "Call Pet 2" },
                { id = 83243, name = "Call Pet 3" },
                { id = 83244, name = "Call Pet 4" },
                { id = 83245, name = "Call Pet 5" }
            },
            reviveAbilities = {
                { id = 982, name = "Revive Pet" }
            },
            modeAbilities = {
                { id = 34477, name = "Misdirection", target = "tank" },
                { id = 259489, name = "Kill Command" },
                { id = 263136, name = "Call of the Master" }
            },
            petAbilities = {
                { id = 263136, name = "Master of the Elements", isAura = true }
            },
            defaultMode = "assist",
            needsStanceControl = true
        }
    },
    ["WARLOCK"] = {
        -- Affliction spec (1)
        [1] = {
            summonAbilities = {
                { id = 688, name = "Summon Imp" },
                { id = 697, name = "Summon Voidwalker" },
                { id = 691, name = "Summon Felhunter" },
                { id = 712, name = "Summon Succubus" },
                { id = 30146, name = "Summon Felguard" },
                { id = 324631, name = "Summon Demonic Tyrant" }
            },
            modeAbilities = {},
            petAbilities = {
                { id = 89792, name = "Flee", target = "pet" },
                { id = 89808, name = "Singe Magic", target = "player" }
            },
            defaultMode = "assist",
            defaultPet = 1,  -- Imp is default for Affliction
            needsStanceControl = false
        },
        -- Demonology spec (2)
        [2] = {
            summonAbilities = {
                { id = 688, name = "Summon Imp" },
                { id = 697, name = "Summon Voidwalker" },
                { id = 691, name = "Summon Felhunter" },
                { id = 712, name = "Summon Succubus" },
                { id = 30146, name = "Summon Felguard" },
                { id = 324631, name = "Summon Demonic Tyrant" }
            },
            modeAbilities = {
                { id = 267171, name = "Demonic Strength", target = "pet" },
                { id = 264119, name = "Summon Vilefiend" },
                { id = 264178, name = "Demonbolt" }
            },
            petAbilities = {
                { id = 267171, name = "Demonic Power", isAura = true },
                { id = 30213, name = "Legion Strike", target = "target" },
                { id = 89751, name = "Felstorm", target = "target" },
                { id = 115746, name = "Fellash", target = "target" }
            },
            defaultMode = "assist",
            defaultPet = 5,  -- Felguard is default for Demonology
            needsStanceControl = false
        },
        -- Destruction spec (3)
        [3] = {
            summonAbilities = {
                { id = 688, name = "Summon Imp" },
                { id = 697, name = "Summon Voidwalker" },
                { id = 691, name = "Summon Felhunter" },
                { id = 712, name = "Summon Succubus" },
                { id = 30146, name = "Summon Felguard" }
            },
            modeAbilities = {},
            petAbilities = {
                { id = 89792, name = "Flee", target = "pet" },
                { id = 17735, name = "Suffering", target = "target" },
                { id = 89808, name = "Singe Magic", target = "player" }
            },
            defaultMode = "assist",
            defaultPet = 1,  -- Imp is default for Destruction
            needsStanceControl = false
        }
    },
    ["DEATHKNIGHT"] = {
        -- Blood spec (1)
        [1] = {
            summonAbilities = {
                { id = 46585, name = "Raise Dead" }
            },
            modeAbilities = {},
            petAbilities = {
                { id = 47482, name = "Leap", target = "target" },
                { id = 47484, name = "Huddle", target = "pet" },
                { id = 47481, name = "Gnaw", target = "target" },
                { id = 47468, name = "Claw", target = "target" }
            },
            defaultMode = "assist",
            needsStanceControl = false
        },
        -- Frost spec (2)
        [2] = {
            summonAbilities = {
                { id = 46585, name = "Raise Dead" }
            },
            modeAbilities = {},
            petAbilities = {
                { id = 47482, name = "Leap", target = "target" },
                { id = 47484, name = "Huddle", target = "pet" },
                { id = 47481, name = "Gnaw", target = "target" },
                { id = 47468, name = "Claw", target = "target" }
            },
            defaultMode = "assist",
            needsStanceControl = false
        },
        -- Unholy spec (3)
        [3] = {
            summonAbilities = {
                { id = 46585, name = "Raise Dead" }
            },
            modeAbilities = {
                { id = 42650, name = "Army of the Dead" },
                { id = 63560, name = "Dark Transformation" }
            },
            petAbilities = {
                { id = 47482, name = "Leap", target = "target" },
                { id = 47484, name = "Huddle", target = "pet" },
                { id = 47481, name = "Gnaw", target = "target" },
                { id = 47468, name = "Claw", target = "target" }
            },
            defaultMode = "assist",
            needsStanceControl = false
        }
    },
    ["MAGE"] = {
        -- All specs
        [0] = {
            summonAbilities = {
                { id = 31687, name = "Summon Water Elemental" }
            },
            modeAbilities = {},
            petAbilities = {
                { id = 33395, name = "Freeze", target = "target" }
            },
            defaultMode = "assist",
            needsStanceControl = false,
            temporary = true  -- Water elemental is temporary for some specs
        }
    },
    ["SHAMAN"] = {
        -- All specs
        [0] = {
            summonAbilities = {
                { id = 2645, name = "Ghost Wolf", isSelf = true }
            },
            modeAbilities = {},
            petAbilities = {},
            defaultMode = "assist",
            needsStanceControl = false,
            temporary = true
        }
    }
}

-- Initialize module
function PetManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events for pet tracking
    API.RegisterEvent("UNIT_PET", function(unit)
        if unit == "player" then
            self:UpdatePetState()
        end
    end)
    
    API.RegisterEvent("PET_BAR_UPDATE", function()
        self:UpdatePetAbilities()
    end)
    
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:UpdatePetConfiguration()
        end
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:UpdatePetConfiguration()
    end)
    
    -- Initial update
    self:UpdatePetConfiguration()
    self:UpdatePetState()
    
    API.PrintDebug("Pet Manager initialized")
    return true
end

-- Register settings
function PetManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("PetManager", {
        petSettings = {
            enablePetManagement = {
                displayName = "Enable Pet Management",
                description = "Automatically manage pet summons and abilities",
                type = "toggle",
                default = true
            },
            autoSummonPet = {
                displayName = "Auto-Summon Pet",
                description = "Automatically summon pet when missing",
                type = "toggle",
                default = true
            },
            autoRevivePet = {
                displayName = "Auto-Revive Pet",
                description = "Automatically revive pet when dead",
                type = "toggle",
                default = true
            },
            preferredPet = {
                displayName = "Preferred Pet",
                description = "Select your preferred pet to summon",
                type = "dropdown",
                options = {},  -- Will be populated based on class
                default = 1
            },
            usePetDefensives = {
                displayName = "Use Pet Defensives",
                description = "Automatically use pet defensive abilities",
                type = "toggle",
                default = true
            },
            usePetOffensives = {
                displayName = "Use Pet Offensives",
                description = "Automatically use pet offensive abilities",
                type = "toggle",
                default = true
            },
            petAttackWithPlayer = {
                displayName = "Pet Attack with Player",
                description = "Pet attacks the same target as the player",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("PetManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function PetManager:ApplySettings(settings)
    -- Apply pet settings
    enablePetManagement = settings.petSettings.enablePetManagement
    autoSummonPet = settings.petSettings.autoSummonPet
    autoRevivePet = settings.petSettings.autoRevivePet
    preferredPet = settings.petSettings.preferredPet
    usePetDefensives = settings.petSettings.usePetDefensives
    usePetOffensives = settings.petSettings.usePetOffensives
    petAttackWithPlayer = settings.petSettings.petAttackWithPlayer
    
    API.PrintDebug("Pet Manager settings applied")
end

-- Update settings from external source
function PetManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enablePetManagement ~= nil then
        enablePetManagement = newSettings.enablePetManagement
    end
end

-- Update pet configuration based on player class and spec
function PetManager:UpdatePetConfiguration()
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization() or 0
    
    -- Reset current configuration
    self.currentConfig = nil
    
    -- Get configurations for this class
    local classConfigs = petConfigurations[playerClass]
    if not classConfigs then return end
    
    -- Try to get spec-specific config, fall back to general class config
    local config = classConfigs[playerSpec] or classConfigs[0]
    if not config then return end
    
    -- Store current configuration
    self.currentConfig = config
    
    -- Update pet abilities
    self:UpdatePetAbilities()
    
    -- Update pet state
    self:UpdatePetState()
    
    -- Update dropdown options for pet selection
    local options = {}
    if config.summonAbilities then
        for i, ability in ipairs(config.summonAbilities) do
            if not ability.isSelf then  -- Skip self-transformations like Ghost Wolf
                table.insert(options, ability.name)
            end
        end
    end
    
    -- Update preferredPet dropdown
    local settings = ConfigRegistry.GetSettings("PetManager")
    if settings and settings.petSettings then
        settings.petSettings.preferredPet.options = options
    end
end

-- Update pet state
function PetManager:UpdatePetState()
    -- Check if player has a pet
    local hasPet = UnitExists("pet")
    
    -- Update pet GUID if it exists
    if hasPet then
        currentPetGUID = UnitGUID("pet")
    else
        currentPetGUID = nil
    end
    
    -- Check pet health if it exists
    local petHealth = 100
    if hasPet then
        petHealth = (UnitHealth("pet") / UnitHealthMax("pet")) * 100
    end
    
    -- Store pet state
    petStates = {
        exists = hasPet,
        guid = currentPetGUID,
        health = petHealth,
        isDead = hasPet and UnitIsDeadOrGhost("pet"),
        isActive = hasPet and not UnitIsDeadOrGhost("pet")
    }
    
    API.PrintDebug("Updated pet state: " .. (hasPet and "Pet exists" or "No pet"))
end

-- Update pet abilities
function PetManager:UpdatePetAbilities()
    -- Reset abilities
    petAbilities = {}
    
    -- Check if we have a pet and a configuration
    if not UnitExists("pet") or not self.currentConfig then
        return
    end
    
    -- Get pet abilities based on current configuration
    if self.currentConfig.petAbilities then
        for _, ability in ipairs(self.currentConfig.petAbilities) do
            -- Check if this ability is available to the pet
            local abilityName = ability.name
            local slot = self:FindPetActionSlot(abilityName)
            
            if slot then
                -- Store with additional information
                table.insert(petAbilities, {
                    name = abilityName,
                    slot = slot,
                    target = ability.target or "target",
                    isAura = ability.isAura or false
                })
            end
        end
    end
    
    API.PrintDebug("Updated pet abilities: " .. #petAbilities)
end

-- Find a pet action slot by name
function PetManager:FindPetActionSlot(abilityName)
    for i = 1, 10 do
        local name, _, _, isToken = GetPetActionInfo(i)
        if name and (name == abilityName or (isToken and _G[name] == abilityName)) then
            return i
        end
    end
    return nil
end

-- Check if we need to summon a pet
function PetManager:NeedToSummonPet()
    -- Skip if disabled or no config
    if not enablePetManagement or not self.currentConfig then
        return false
    end
    
    -- Skip if we have a pet that's alive
    if petStates.isActive then
        return false
    end
    
    -- If pet is dead and we can revive, prioritize reviving
    if petStates.isDead and autoRevivePet then
        return "revive"
    end
    
    -- If no pet and we can summon, do that
    if not petStates.exists and autoSummonPet then
        return "summon"
    end
    
    return false
end

-- Get the appropriate pet summon ability
function PetManager:GetPetSummonAbility()
    -- Skip if no config
    if not self.currentConfig then
        return nil
    end
    
    -- Check if we need to revive
    if self:NeedToSummonPet() == "revive" and self.currentConfig.reviveAbilities then
        for _, ability in ipairs(self.currentConfig.reviveAbilities) do
            if API.IsSpellKnown(ability.id) and API.IsSpellUsable(ability.id) then
                return ability
            end
        end
    end
    
    -- Check if we need to summon
    if self:NeedToSummonPet() == "summon" and self.currentConfig.summonAbilities then
        -- Get settings
        local settings = ConfigRegistry.GetSettings("PetManager")
        local preferredIndex = 1
        
        if settings and settings.petSettings and settings.petSettings.preferredPet then
            preferredIndex = settings.petSettings.preferredPet
        elseif self.currentConfig.defaultPet then
            preferredIndex = self.currentConfig.defaultPet
        end
        
        -- Try preferred pet first
        if preferredIndex <= #self.currentConfig.summonAbilities then
            local ability = self.currentConfig.summonAbilities[preferredIndex]
            if API.IsSpellKnown(ability.id) and API.IsSpellUsable(ability.id) then
                return ability
            end
        end
        
        -- Try any pet if preferred not available
        for _, ability in ipairs(self.currentConfig.summonAbilities) do
            if API.IsSpellKnown(ability.id) and API.IsSpellUsable(ability.id) then
                return ability
            end
        end
    end
    
    return nil
end

-- Process pet management tasks
function PetManager.ProcessPet(combatState)
    -- Skip if disabled
    if not enablePetManagement then
        return nil
    end
    
    -- Check if we need to summon or revive pet (less frequent check)
    if GetTime() - lastPetSummonCheck > PET_SUMMON_CHECK_INTERVAL then
        local petManager = PetManager
        local needPet = petManager:NeedToSummonPet()
        
        if needPet then
            local summonAbility = petManager:GetPetSummonAbility()
            if summonAbility then
                lastPetSummonCheck = GetTime()
                
                -- Return the summon/revive command
                return {
                    id = summonAbility.id,
                    target = "player"
                }
            end
        end
        
        lastPetSummonCheck = GetTime()
    end
    
    -- Skip pet abilities if pet not active or too soon since last ability
    if not petStates.isActive or GetTime() - lastPetAbilityTime < MIN_PET_ABILITY_INTERVAL then
        return nil
    end
    
    -- Check for pet attack if pet should attack with player
    local settings = ConfigRegistry.GetSettings("PetManager") or { petSettings = {} }
    local petAttackWithPlayer = settings.petSettings.petAttackWithPlayer
    
    if petAttackWithPlayer and combatState.inCombat and UnitExists("target") and not UnitIsFriend("player", "target") then
        -- Check if pet is attacking the player's target
        if UnitExists("pettarget") and not UnitIsUnit("pettarget", "target") then
            -- Pet should attack player's target
            lastPetAbilityTime = GetTime()
            
            -- Special case: Send using PetAttack() instead of spell ID
            return {
                petAction = "PetAttack",
                target = "target"
            }
        end
    end
    
    -- Process pet abilities
    local usePetOffensives = settings.petSettings.usePetOffensives
    local usePetDefensives = settings.petSettings.usePetDefensives
    
    for _, ability in ipairs(petAbilities) do
        -- Skip non-offensive abilities if offensive usage disabled
        if ability.target == "target" and not usePetOffensives then
            -- Skip offensive abilities
        elseif ability.target == "pet" and not usePetDefensives then
            -- Skip defensive abilities
        else
            -- Check if this ability should be used (pet action slots)
            local usable = select(2, GetPetActionCooldown(ability.slot))
            
            if usable == 0 then  -- Not on cooldown
                lastPetAbilityTime = GetTime()
                
                -- Return pet action command
                return {
                    petAction = "PetActionButton",
                    actionSlot = ability.slot,
                    target = ability.target
                }
            end
        end
    end
    
    return nil
end

-- Return module
return PetManager