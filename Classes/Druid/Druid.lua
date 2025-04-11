------------------------------------------
-- WindrunnerRotations - Druid Class Module
-- Author: VortexQ8
------------------------------------------

-- Create base class node in addon table
local addonName, addon = ...
if not addon.Classes then addon.Classes = {} end
addon.Classes.Druid = {}

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl

-- Constants
local DRUID_CLASS_ID = 11 -- WoW class ID for Druid

-- Initialize the class module
function addon.Classes.Druid:Initialize()
    self:InitializeVariables()
    self:RegisterSpells()
    self:RegisterSettings()
    self:LoadSpecModules()
    
    -- Print initialization message for debugging
    API.PrintDebug("Druid module initialized")
    
    return true
end

-- Initialize class-wide variables
function addon.Classes.Druid:InitializeVariables()
    self.specModules = {}
    self.activeSpec = API.GetActiveSpecID()
    
    -- Cache commonly used spell IDs 
    self.spells = {
        -- General Druid abilities
        MOONFIRE = 8921,
        SUNFIRE = 93402,
        WRATH = 5176,
        STARFIRE = 194153,
        REGROWTH = 8936,
        REJUVENATION = 774,
        LIFEBLOOM = 33763,
        REBIRTH = 20484,
        SWIFTMEND = 18562,
        WILD_GROWTH = 48438,
        INNERVATE = 29166,
        BARKSKIN = 22812,
        BEAR_FORM = 5487,
        CAT_FORM = 768,
        TRAVEL_FORM = 783,
        MOONKIN_FORM = 24858,
        TYPHOON = 132469,
        STAMPEDING_ROAR = 106898,
        REMOVE_CORRUPTION = 2782,
        IRONFUR = 192081,
        FRENZIED_REGENERATION = 22842,
        HIBERNATE = 2637,
        ENTANGLING_ROOTS = 339,
        SOOTHE = 2908,
        CYCLONE = 33786,
        PROWL = 5215,
        
        -- Covenant abilities (Shadowlands)
        CONVOKE_THE_SPIRITS = 323764,
        RAVENOUS_FRENZY = 323546,
        KINDRED_SPIRITS = 326434,
        ADAPTIVE_SWARM = 325727
    }
    
    return true
end

-- Register spell effects and handlers
function addon.Classes.Druid:RegisterSpells()
    -- Register general druid spells for tracking
    API.RegisterSpell(self.spells.MOONFIRE)
    API.RegisterSpell(self.spells.SUNFIRE)
    API.RegisterSpell(self.spells.WRATH)
    API.RegisterSpell(self.spells.STARFIRE)
    API.RegisterSpell(self.spells.REGROWTH)
    API.RegisterSpell(self.spells.REJUVENATION)
    API.RegisterSpell(self.spells.LIFEBLOOM)
    API.RegisterSpell(self.spells.REBIRTH)
    API.RegisterSpell(self.spells.SWIFTMEND)
    API.RegisterSpell(self.spells.WILD_GROWTH)
    API.RegisterSpell(self.spells.INNERVATE)
    API.RegisterSpell(self.spells.BARKSKIN)
    API.RegisterSpell(self.spells.BEAR_FORM)
    API.RegisterSpell(self.spells.CAT_FORM)
    API.RegisterSpell(self.spells.TRAVEL_FORM)
    API.RegisterSpell(self.spells.MOONKIN_FORM)
    API.RegisterSpell(self.spells.TYPHOON)
    API.RegisterSpell(self.spells.STAMPEDING_ROAR)
    API.RegisterSpell(self.spells.REMOVE_CORRUPTION)
    API.RegisterSpell(self.spells.IRONFUR)
    API.RegisterSpell(self.spells.FRENZIED_REGENERATION)
    API.RegisterSpell(self.spells.HIBERNATE)
    API.RegisterSpell(self.spells.ENTANGLING_ROOTS)
    API.RegisterSpell(self.spells.SOOTHE)
    API.RegisterSpell(self.spells.CYCLONE)
    API.RegisterSpell(self.spells.PROWL)
    
    -- Register covenant abilities
    API.RegisterSpell(self.spells.CONVOKE_THE_SPIRITS)
    API.RegisterSpell(self.spells.RAVENOUS_FRENZY)
    API.RegisterSpell(self.spells.KINDRED_SPIRITS)
    API.RegisterSpell(self.spells.ADAPTIVE_SWARM)
    
    return true
end

-- Register class-wide settings in the ConfigRegistry
function addon.Classes.Druid:RegisterSettings()
    -- Class-wide settings group
    ConfigRegistry:RegisterSettings("Druid", {
        generalSettings = {
            useBarkskin = {
                displayName = "Auto Barkskin",
                description = "Automatically use Barkskin when in danger",
                type = "toggle",
                default = true
            },
            barkskinThreshold = {
                displayName = "Barkskin Health Threshold",
                description = "Health percentage to use Barkskin",
                type = "slider",
                min = 10,
                max = 100,
                default = 60
            },
            useDispel = {
                displayName = "Auto Dispel",
                description = "Automatically Remove Corruption/Nature's Cure on party members",
                type = "toggle",
                default = true
            },
            autoRebirth = {
                displayName = "Auto Rebirth",
                description = "Automatically battle resurrect dead players",
                type = "toggle",
                default = false
            },
            rebirthPriority = {
                displayName = "Rebirth Priority",
                description = "Prioritize which roles to resurrect first",
                type = "dropdown",
                options = {"Healer,Tank,DPS", "Tank,Healer,DPS", "DPS,Healer,Tank"},
                default = "Healer,Tank,DPS"
            },
            useOutOfCombatForms = {
                displayName = "Use Forms Out of Combat",
                description = "Automatically switch to appropriate forms out of combat",
                type = "toggle",
                default = true
            },
            interruptEnabled = {
                displayName = "Enable Interrupts",
                description = "Automatically interrupt enemy spellcasting",
                type = "toggle",
                default = true
            },
            interruptDelay = {
                displayName = "Interrupt Delay",
                description = "Random delay for interrupt (milliseconds)",
                type = "slider",
                min = 0,
                max = 1000,
                default = 200
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Stampeding Roar controls
            stampedingRoar = AAC.RegisterAbility(self.spells.STAMPEDING_ROAR, {
                enabled = true,
                groupMovementThreshold = 3,
                movementSpeedThreshold = 50
            }),
            
            -- Typhoon controls
            typhoon = AAC.RegisterAbility(self.spells.TYPHOON, {
                enabled = true,
                minEnemies = 2,
                maxDistance = 8
            }),
            
            -- Innervate controls
            innervate = AAC.RegisterAbility(self.spells.INNERVATE, {
                enabled = true,
                targetPriority = "self,healer",
                manaThreshold = 70
            })
        }
    })
    
    return true
end

-- Load specialization modules
function addon.Classes.Druid:LoadSpecModules()
    -- Define spec IDs for Druid
    local BALANCE_SPEC_ID = 102
    local FERAL_SPEC_ID = 103
    local GUARDIAN_SPEC_ID = 104
    local RESTORATION_SPEC_ID = 105
    
    -- Try to load each specialization module
    local specs = {
        [BALANCE_SPEC_ID] = "Balance",
        [FERAL_SPEC_ID] = "Feral",
        [GUARDIAN_SPEC_ID] = "Guardian",
        [RESTORATION_SPEC_ID] = "Restoration"
    }
    
    -- Load the modules
    for specID, specName in pairs(specs) do
        -- Try to load and initialize the module
        local success, errorMsg = pcall(function()
            -- Require the spec module
            local specFile = string.format("Classes.Druid.%s", specName)
            self.specModules[specID] = addon:RequireModule(specFile)
            
            -- Initialize if available
            if self.specModules[specID] and self.specModules[specID].Initialize then
                self.specModules[specID]:Initialize()
                API.PrintDebug("Loaded " .. specName .. " Druid module")
            end
        end)
        
        -- Log errors if module loading failed
        if not success then
            API.PrintError("Failed to load " .. specName .. " Druid module: " .. tostring(errorMsg))
        end
    end
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    return true
end

-- Handle specialization changes
function addon.Classes.Druid:OnSpecializationChanged()
    local newSpecID = API.GetActiveSpecID()
    
    -- If spec changed, update active spec
    if newSpecID ~= self.activeSpec then
        API.PrintDebug("Druid specialization changed to: " .. tostring(newSpecID))
        self.activeSpec = newSpecID
        
        -- Call spec-specific handlers if they exist
        if self.specModules[newSpecID] and self.specModules[newSpecID].OnSpecializationChanged then
            self.specModules[newSpecID]:OnSpecializationChanged()
        end
    end
    
    return true
end

-- Main rotation function - delegates to the active spec
function addon.Classes.Druid:RunRotation()
    -- Check if we are a druid
    if API.GetPlayerClass() ~= DRUID_CLASS_ID then
        return false
    end
    
    -- Handle general druid logic first (forms, defensives, etc.)
    self:HandleGeneralAbilities()
    
    -- Run the specialization-specific rotation
    local activeSpec = self.activeSpec
    if self.specModules[activeSpec] and self.specModules[activeSpec].RunRotation then
        return self.specModules[activeSpec]:RunRotation()
    end
    
    return false
end

-- Handle general druid abilities used across all specs
function addon.Classes.Druid:HandleGeneralAbilities()
    -- Skip if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("Druid")
    
    -- Handle defensive cooldowns
    if settings.generalSettings.useBarkskin then
        local healthPct = API.GetPlayerHealthPercent()
        
        if healthPct <= settings.generalSettings.barkskinThreshold and
           API.CanCast(self.spells.BARKSKIN) then
            API.CastSpell(self.spells.BARKSKIN)
            return true
        end
    end
    
    -- Handle Stampeding Roar
    if settings.abilityControls.stampedingRoar.enabled and 
       API.CanCast(self.spells.STAMPEDING_ROAR) then
        
        -- Count group members that are moving
        local movingCount = 0
        local groupSize = API.GetGroupSize()
        
        for i = 1, groupSize do
            local unit = API.GetGroupUnitID(i)
            if unit and API.IsUnitMoving(unit) then
                movingCount = movingCount + 1
            end
        end
        
        -- Use Stampeding Roar if enough group members are moving
        if movingCount >= settings.abilityControls.stampedingRoar.groupMovementThreshold then
            API.CastSpell(self.spells.STAMPEDING_ROAR)
            return true
        end
    end
    
    -- Handle battle resurrections (Rebirth)
    if settings.generalSettings.autoRebirth and 
       API.IsInCombat() and 
       API.CanCast(self.spells.REBIRTH) then
        
        -- Find a dead player to resurrect based on priority
        local priorityOrder = {}
        
        -- Parse priority string
        for role in string.gmatch(settings.generalSettings.rebirthPriority, "([^,]+)") do
            table.insert(priorityOrder, role:trim():upper())
        end
        
        local targetToRez = nil
        
        -- Check each role in priority order
        for _, role in ipairs(priorityOrder) do
            local groupSize = API.GetGroupSize()
            
            for i = 1, groupSize do
                local unit = API.GetGroupUnitID(i)
                if unit and API.UnitIsDead(unit) and API.GetUnitRole(unit) == role then
                    targetToRez = unit
                    break
                end
            end
            
            if targetToRez then
                break
            end
        end
        
        -- Cast Rebirth if we found a target
        if targetToRez then
            API.CastSpellOnUnit(self.spells.REBIRTH, targetToRez)
            return true
        end
    end
    
    -- Handle dispelling
    if settings.generalSettings.useDispel then
        -- Check if we can dispel
        local canDispelMagic = (self.activeSpec == 105) -- Restoration can dispel magic
        local dispelSpell = self.spells.REMOVE_CORRUPTION
        
        if canDispelMagic then
            dispelSpell = 88423 -- Nature's Cure for Restoration
        end
        
        if API.CanCast(dispelSpell) then
            -- Check self first
            if API.NeedsDispel("player", canDispelMagic) then
                API.CastSpellOnUnit(dispelSpell, "player")
                return true
            end
            
            -- Check group members
            local groupSize = API.GetGroupSize()
            
            for i = 1, groupSize do
                local unit = API.GetGroupUnitID(i)
                if unit and API.NeedsDispel(unit, canDispelMagic) then
                    API.CastSpellOnUnit(dispelSpell, unit)
                    return true
                end
            end
        end
    end
    
    -- Handle out of combat form switching
    if settings.generalSettings.useOutOfCombatForms and not API.IsInCombat() then
        -- Switch to travel form if moving and outdoors
        if API.IsPlayerMoving() and API.IsOutdoors() and not API.PlayerHasBuff(self.spells.TRAVEL_FORM) then
            API.CastSpell(self.spells.TRAVEL_FORM)
            return true
        end
        
        -- Switch to appropriate form based on spec when standing still
        if not API.IsPlayerMoving() then
            local specID = self.activeSpec
            
            if specID == 102 and not API.PlayerHasBuff(self.spells.MOONKIN_FORM) then
                -- Balance - Moonkin Form
                API.CastSpell(self.spells.MOONKIN_FORM)
                return true
            elseif specID == 103 and not API.PlayerHasBuff(self.spells.CAT_FORM) then
                -- Feral - Cat Form
                API.CastSpell(self.spells.CAT_FORM)
                return true
            elseif specID == 104 and not API.PlayerHasBuff(self.spells.BEAR_FORM) then
                -- Guardian - Bear Form
                API.CastSpell(self.spells.BEAR_FORM)
                return true
            end
            -- Restoration doesn't need a particular form when out of combat
        end
    end
    
    return false
end

-- Register the class with the addon
addon:RegisterClass("DRUID", addon.Classes.Druid)