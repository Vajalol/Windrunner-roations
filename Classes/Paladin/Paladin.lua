------------------------------------------
-- WindrunnerRotations - Paladin Class Module
-- Author: VortexQ8
------------------------------------------

-- Create base class node in addon table
local addonName, addon = ...
if not addon.Classes then addon.Classes = {} end
addon.Classes.Paladin = {}

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl

-- Constants
local PALADIN_CLASS_ID = 2 -- WoW class ID for Paladin

-- Initialize the class module
function addon.Classes.Paladin:Initialize()
    self:InitializeVariables()
    self:RegisterSpells()
    self:RegisterSettings()
    self:LoadSpecModules()
    
    -- Print initialization message for debugging
    API.PrintDebug("Paladin module initialized")
    
    return true
end

-- Initialize class-wide variables
function addon.Classes.Paladin:InitializeVariables()
    self.specModules = {}
    self.activeSpec = API.GetActiveSpecID()
    
    -- Cache commonly used spell IDs 
    self.spells = {
        -- General Paladin abilities
        DIVINE_SHIELD = 642,
        BLESSING_OF_PROTECTION = 1022,
        BLESSING_OF_FREEDOM = 1044,
        BLESSING_OF_SACRIFICE = 6940,
        CLEANSE = 4987,
        DEVOTION_AURA = 465,
        HAMMER_OF_JUSTICE = 853,
        REDEMPTION = 7328,
        LAY_ON_HANDS = 633,
        FLASH_OF_LIGHT = 19750,
        WORD_OF_GLORY = 85673,
        DIVINE_STEED = 190784,
        CONSECRATION = 26573,
        REBUKE = 96231,
        
        -- Covenant abilities (Shadowlands)
        DIVINE_TOLL = 304971,
        ASHEN_HALLOW = 316958,
        VANQUISHERS_HAMMER = 328204,
        BLESSING_OF_SUMMER = 328620
    }
    
    return true
end

-- Register spell effects and handlers
function addon.Classes.Paladin:RegisterSpells()
    -- Register general paladin spells for tracking
    API.RegisterSpell(self.spells.DIVINE_SHIELD)
    API.RegisterSpell(self.spells.BLESSING_OF_PROTECTION)
    API.RegisterSpell(self.spells.BLESSING_OF_FREEDOM)
    API.RegisterSpell(self.spells.BLESSING_OF_SACRIFICE)
    API.RegisterSpell(self.spells.CLEANSE)
    API.RegisterSpell(self.spells.DEVOTION_AURA)
    API.RegisterSpell(self.spells.HAMMER_OF_JUSTICE)
    API.RegisterSpell(self.spells.REDEMPTION)
    API.RegisterSpell(self.spells.LAY_ON_HANDS)
    API.RegisterSpell(self.spells.FLASH_OF_LIGHT)
    API.RegisterSpell(self.spells.WORD_OF_GLORY)
    API.RegisterSpell(self.spells.DIVINE_STEED)
    API.RegisterSpell(self.spells.CONSECRATION)
    API.RegisterSpell(self.spells.REBUKE)
    
    -- Register covenant abilities
    API.RegisterSpell(self.spells.DIVINE_TOLL)
    API.RegisterSpell(self.spells.ASHEN_HALLOW)
    API.RegisterSpell(self.spells.VANQUISHERS_HAMMER)
    API.RegisterSpell(self.spells.BLESSING_OF_SUMMER)
    
    return true
end

-- Register class-wide settings in the ConfigRegistry
function addon.Classes.Paladin:RegisterSettings()
    -- Class-wide settings group
    ConfigRegistry:RegisterSettings("Paladin", {
        generalSettings = {
            useSelfHeals = {
                displayName = "Use Self Healing",
                description = "Automatically use Word of Glory when health is low",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensive Abilities",
                description = "Automatically use defensive abilities when in danger",
                type = "toggle",
                default = true
            },
            lowHealthDefensiveThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage to use defensive abilities",
                type = "slider",
                min = 1,
                max = 100,
                default = 30
            },
            layOnHandsThreshold = {
                displayName = "Lay on Hands Threshold",
                description = "Health percentage to use Lay on Hands",
                type = "slider",
                min = 1,
                max = 30,
                default = 15
            },
            useMovementAbilities = {
                displayName = "Use Divine Steed",
                description = "Automatically use Divine Steed when moving long distances",
                type = "toggle",
                default = true
            },
            interruptEnabled = {
                displayName = "Enable Interrupts",
                description = "Automatically interrupt enemy spellcasting with Rebuke",
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
            -- Divine Shield controls
            divineShield = AAC.RegisterAbility(self.spells.DIVINE_SHIELD, {
                enabled = true,
                healthThreshold = 20,
                emergencyOnly = false,
                cancelAurasOnUse = true
            }),
            
            -- Blessing of Protection controls
            blessingOfProtection = AAC.RegisterAbility(self.spells.BLESSING_OF_PROTECTION, {
                enabled = true,
                targetPriority = "self,tank,healer,dps",
                healthThreshold = 25,
                emergencyOnly = true
            }),
            
            -- Blessing of Freedom controls
            blessingOfFreedom = AAC.RegisterAbility(self.spells.BLESSING_OF_FREEDOM, {
                enabled = true,
                removeRootOnly = false,
                removeSlowOnly = false
            })
        }
    })
    
    return true
end

-- Load specialization modules
function addon.Classes.Paladin:LoadSpecModules()
    -- Define spec IDs for Paladin
    local HOLY_SPEC_ID = 65
    local PROTECTION_SPEC_ID = 66
    local RETRIBUTION_SPEC_ID = 70
    
    -- Try to load each specialization module
    local specs = {
        [HOLY_SPEC_ID] = "Holy",
        [PROTECTION_SPEC_ID] = "Protection",
        [RETRIBUTION_SPEC_ID] = "Retribution"
    }
    
    -- Load the modules
    for specID, specName in pairs(specs) do
        -- Try to load and initialize the module
        local success, errorMsg = pcall(function()
            -- Require the spec module
            local specFile = string.format("Classes.Paladin.%s", specName)
            self.specModules[specID] = addon:RequireModule(specFile)
            
            -- Initialize if available
            if self.specModules[specID] and self.specModules[specID].Initialize then
                self.specModules[specID]:Initialize()
                API.PrintDebug("Loaded " .. specName .. " Paladin module")
            end
        end)
        
        -- Log errors if module loading failed
        if not success then
            API.PrintError("Failed to load " .. specName .. " Paladin module: " .. tostring(errorMsg))
        end
    end
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    return true
end

-- Handle specialization changes
function addon.Classes.Paladin:OnSpecializationChanged()
    local newSpecID = API.GetActiveSpecID()
    
    -- If spec changed, update active spec
    if newSpecID ~= self.activeSpec then
        API.PrintDebug("Paladin specialization changed to: " .. tostring(newSpecID))
        self.activeSpec = newSpecID
        
        -- Call spec-specific handlers if they exist
        if self.specModules[newSpecID] and self.specModules[newSpecID].OnSpecializationChanged then
            self.specModules[newSpecID]:OnSpecializationChanged()
        end
    end
    
    return true
end

-- Main rotation function - delegates to the active spec
function addon.Classes.Paladin:RunRotation()
    -- Check if we are a paladin
    if API.GetPlayerClass() ~= PALADIN_CLASS_ID then
        return false
    end
    
    -- Handle general paladin logic first (buffs, defensives, etc.)
    self:HandleGeneralAbilities()
    
    -- Run the specialization-specific rotation
    local activeSpec = self.activeSpec
    if self.specModules[activeSpec] and self.specModules[activeSpec].RunRotation then
        return self.specModules[activeSpec]:RunRotation()
    end
    
    return false
end

-- Handle general paladin abilities used across all specs
function addon.Classes.Paladin:HandleGeneralAbilities()
    -- Skip if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("Paladin")
    
    -- Handle divine steed for movement
    if settings.generalSettings.useMovementAbilities then
        -- Check if player has been moving for more than 2 seconds
        if API.IsPlayerMoving() and API.GetPlayerMovingTime() > 2 and API.CanCast(self.spells.DIVINE_STEED) then
            API.CastSpell(self.spells.DIVINE_STEED)
            return true
        end
    end
    
    -- Handle self healing when low
    if settings.generalSettings.useSelfHeals then
        local healthPct = API.GetPlayerHealthPercent()
        
        -- Use Lay on Hands in emergency
        if healthPct <= settings.generalSettings.layOnHandsThreshold and 
           API.CanCast(self.spells.LAY_ON_HANDS) then
            API.CastSpellOnUnit(self.spells.LAY_ON_HANDS, "player")
            return true
        end
        
        -- Use Word of Glory for self healing
        if healthPct <= settings.generalSettings.lowHealthDefensiveThreshold and 
           API.CanCast(self.spells.WORD_OF_GLORY) and
           API.GetPlayerPower() >= 1 then -- Requires at least 1 Holy Power
            API.CastSpellOnUnit(self.spells.WORD_OF_GLORY, "player")
            return true
        end
    end
    
    -- Handle defensive cooldowns
    if settings.generalSettings.useDefensives then
        local healthPct = API.GetPlayerHealthPercent()
        
        -- Use Divine Shield
        if healthPct <= settings.abilityControls.divineShield.healthThreshold and
           settings.abilityControls.divineShield.enabled and
           (not settings.abilityControls.divineShield.emergencyOnly or API.IsInCombat()) and
           API.CanCast(self.spells.DIVINE_SHIELD) then
            
            API.CastSpell(self.spells.DIVINE_SHIELD)
            
            -- Cancel harmful auras if setting enabled
            if settings.abilityControls.divineShield.cancelAurasOnUse then
                C_Timer.After(0.1, function()
                    API.CancelHarmfulDebuffs()
                end)
            end
            
            return true
        end
        
        -- Use Blessing of Protection on self
        if healthPct <= settings.abilityControls.blessingOfProtection.healthThreshold and
           settings.abilityControls.blessingOfProtection.enabled and
           settings.abilityControls.blessingOfProtection.targetPriority:find("self") and
           (not settings.abilityControls.blessingOfProtection.emergencyOnly or API.IsInCombat()) and
           API.CanCast(self.spells.BLESSING_OF_PROTECTION) then
            
            API.CastSpellOnUnit(self.spells.BLESSING_OF_PROTECTION, "player")
            return true
        end
        
        -- Use Blessing of Freedom to break CC
        if settings.abilityControls.blessingOfFreedom.enabled and
           API.CanCast(self.spells.BLESSING_OF_FREEDOM) then
            
            -- Check if player is rooted or slowed
            local isRooted = API.IsUnitRooted("player")
            local isSlowed = API.IsUnitSlowed("player")
            
            -- Apply based on settings
            if (isRooted and not settings.abilityControls.blessingOfFreedom.removeSlowOnly) or
               (isSlowed and not settings.abilityControls.blessingOfFreedom.removeRootOnly) then
                API.CastSpellOnUnit(self.spells.BLESSING_OF_FREEDOM, "player")
                return true
            end
        end
    end
    
    -- Interrupt handling
    if settings.generalSettings.interruptEnabled then
        -- Get target casting info
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and API.CanCast(self.spells.REBUKE) and 
           not API.IsSpellOnCooldown(self.spells.REBUKE) then
            -- Check if spell should be interrupted
            local shouldInterrupt, delayInterrupt = AAC.ShouldUseAbility(
                self.spells.REBUKE, 
                targetSpell,
                settings.generalSettings.interruptDelay
            )
            
            if shouldInterrupt then
                -- Delay interrupt based on settings
                C_Timer.After(delayInterrupt/1000, function()
                    API.CastSpell(self.spells.REBUKE)
                end)
                return true
            end
        end
    end
    
    return false
end

-- Register the class with the addon
addon:RegisterClass("PALADIN", addon.Classes.Paladin)