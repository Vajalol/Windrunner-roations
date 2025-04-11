------------------------------------------
-- WindrunnerRotations - Warrior Class Module
-- Author: VortexQ8
------------------------------------------

-- Create base class node in addon table
local addonName, addon = ...
if not addon.Classes then addon.Classes = {} end
addon.Classes.Warrior = {}

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl

-- Constants
local WARRIOR_CLASS_ID = 1 -- WoW class ID for Warrior

-- Initialize the class module
function addon.Classes.Warrior:Initialize()
    self:InitializeVariables()
    self:RegisterSpells()
    self:RegisterSettings()
    self:LoadSpecModules()
    
    -- Print initialization message for debugging
    API.PrintDebug("Warrior module initialized")
    
    return true
end

-- Initialize class-wide variables
function addon.Classes.Warrior:InitializeVariables()
    self.specModules = {}
    self.activeSpec = API.GetActiveSpecID()
    
    -- Cache commonly used spell IDs 
    self.spells = {
        -- General Warrior abilities
        BATTLE_SHOUT = 6673,
        CHARGE = 100,
        EXECUTE = 163201, -- Execute spell ID for all specializations
        HAMSTRING = 1715,
        HEROIC_LEAP = 6544,
        HEROIC_THROW = 57755,
        IGNORE_PAIN = 190456,
        INTIMIDATING_SHOUT = 5246,
        PUMMEL = 6552,
        RALLYING_CRY = 97462,
        SHATTERING_THROW = 64382,
        SHIELD_BLOCK = 2565,
        SHIELD_SLAM = 23922,
        SPELL_REFLECTION = 23920,
        STORM_BOLT = 107570,
        TAUNT = 355,
        THUNDEROUS_ROAR = 384318,
        VICTORIOUS = 32216, -- Buff from Victory Rush
        VICTORY_RUSH = 34428,
        DEFENSIVE_STANCE = 386208,
        BATTLE_STANCE = 386164,
        BERSERKER_STANCE = 386196,
        
        -- Covenant abilities (Shadowlands)
        CONQUERORS_BANNER = 324143,
        SPEAR_OF_BASTION = 307865,
        ANCIENT_AFTERSHOCK = 325886,
        CONDEMN = 317349
    }
    
    return true
end

-- Register spell effects and handlers
function addon.Classes.Warrior:RegisterSpells()
    -- Register general warrior spells for tracking
    API.RegisterSpell(self.spells.BATTLE_SHOUT)
    API.RegisterSpell(self.spells.CHARGE)
    API.RegisterSpell(self.spells.EXECUTE)
    API.RegisterSpell(self.spells.HAMSTRING)
    API.RegisterSpell(self.spells.HEROIC_LEAP)
    API.RegisterSpell(self.spells.HEROIC_THROW)
    API.RegisterSpell(self.spells.IGNORE_PAIN)
    API.RegisterSpell(self.spells.INTIMIDATING_SHOUT)
    API.RegisterSpell(self.spells.PUMMEL)
    API.RegisterSpell(self.spells.RALLYING_CRY)
    API.RegisterSpell(self.spells.SHATTERING_THROW)
    API.RegisterSpell(self.spells.SHIELD_BLOCK)
    API.RegisterSpell(self.spells.SHIELD_SLAM)
    API.RegisterSpell(self.spells.SPELL_REFLECTION)
    API.RegisterSpell(self.spells.STORM_BOLT)
    API.RegisterSpell(self.spells.TAUNT)
    API.RegisterSpell(self.spells.THUNDEROUS_ROAR)
    API.RegisterSpell(self.spells.VICTORY_RUSH)
    API.RegisterSpell(self.spells.DEFENSIVE_STANCE)
    API.RegisterSpell(self.spells.BATTLE_STANCE)
    API.RegisterSpell(self.spells.BERSERKER_STANCE)
    
    -- Register covenant abilities
    API.RegisterSpell(self.spells.CONQUERORS_BANNER)
    API.RegisterSpell(self.spells.SPEAR_OF_BASTION)
    API.RegisterSpell(self.spells.ANCIENT_AFTERSHOCK)
    API.RegisterSpell(self.spells.CONDEMN)
    
    return true
end

-- Register class-wide settings in the ConfigRegistry
function addon.Classes.Warrior:RegisterSettings()
    -- Class-wide settings group
    ConfigRegistry:RegisterSettings("Warrior", {
        generalSettings = {
            useBuffs = {
                displayName = "Auto Buff",
                description = "Automatically cast Battle Shout when missing",
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
                default = 40
            },
            autoCharge = {
                displayName = "Auto Charge",
                description = "Automatically Charge to targets out of melee range",
                type = "toggle",
                default = true
            },
            chargeMinRange = {
                displayName = "Charge Minimum Range",
                description = "Minimum distance to use Charge (yards)",
                type = "slider",
                min = 8,
                max = 25,
                default = 10
            },
            interruptEnabled = {
                displayName = "Enable Interrupts",
                description = "Automatically interrupt enemy spellcasting with Pummel",
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
            },
            useVictoryRush = {
                displayName = "Use Victory Rush",
                description = "Automatically use Victory Rush when available for healing",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Rally controls
            rallyCry = AAC.RegisterAbility(self.spells.RALLYING_CRY, {
                enabled = true,
                healthThreshold = 35,
                partyMembersThreshold = 2
            }),
            
            -- Intimidating Shout controls
            intimidatingShout = AAC.RegisterAbility(self.spells.INTIMIDATING_SHOUT, {
                enabled = true,
                minEnemies = 3,
                panicButton = true,
                panicButtonHealth = 25
            }),
            
            -- Spell Reflection controls
            spellReflection = AAC.RegisterAbility(self.spells.SPELL_REFLECTION, {
                enabled = true,
                prioritySpells = "Chaos Bolt,Pyroblast,Glacial Spike",
                minimumCastTimeRemaining = 0.4
            })
        }
    })
    
    return true
end

-- Load specialization modules
function addon.Classes.Warrior:LoadSpecModules()
    -- Define spec IDs for Warrior
    local ARMS_SPEC_ID = 71
    local FURY_SPEC_ID = 72
    local PROT_SPEC_ID = 73
    
    -- Try to load each specialization module
    local specs = {
        [ARMS_SPEC_ID] = "Arms",
        [FURY_SPEC_ID] = "Fury",
        [PROT_SPEC_ID] = "Protection"
    }
    
    -- Load the modules
    for specID, specName in pairs(specs) do
        -- Try to load and initialize the module
        local success, errorMsg = pcall(function()
            -- Require the spec module
            local specFile = string.format("Classes.Warrior.%s", specName)
            self.specModules[specID] = addon:RequireModule(specFile)
            
            -- Initialize if available
            if self.specModules[specID] and self.specModules[specID].Initialize then
                self.specModules[specID]:Initialize()
                API.PrintDebug("Loaded " .. specName .. " Warrior module")
            end
        end)
        
        -- Log errors if module loading failed
        if not success then
            API.PrintError("Failed to load " .. specName .. " Warrior module: " .. tostring(errorMsg))
        end
    end
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    return true
end

-- Handle specialization changes
function addon.Classes.Warrior:OnSpecializationChanged()
    local newSpecID = API.GetActiveSpecID()
    
    -- If spec changed, update active spec
    if newSpecID ~= self.activeSpec then
        API.PrintDebug("Warrior specialization changed to: " .. tostring(newSpecID))
        self.activeSpec = newSpecID
        
        -- Call spec-specific handlers if they exist
        if self.specModules[newSpecID] and self.specModules[newSpecID].OnSpecializationChanged then
            self.specModules[newSpecID]:OnSpecializationChanged()
        end
    end
    
    return true
end

-- Main rotation function - delegates to the active spec
function addon.Classes.Warrior:RunRotation()
    -- Check if we are a warrior
    if API.GetPlayerClass() ~= WARRIOR_CLASS_ID then
        return false
    end
    
    -- Handle general warrior logic first (buffs, defensives, etc.)
    self:HandleGeneralAbilities()
    
    -- Run the specialization-specific rotation
    local activeSpec = self.activeSpec
    if self.specModules[activeSpec] and self.specModules[activeSpec].RunRotation then
        return self.specModules[activeSpec]:RunRotation()
    end
    
    return false
end

-- Handle general warrior abilities used across all specs
function addon.Classes.Warrior:HandleGeneralAbilities()
    -- Skip if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("Warrior")
    
    -- Auto buff with Battle Shout
    if settings.generalSettings.useBuffs then
        if not API.PlayerHasBuff(self.spells.BATTLE_SHOUT) and API.CanCast(self.spells.BATTLE_SHOUT) then
            API.CastSpell(self.spells.BATTLE_SHOUT)
            return true
        end
    end
    
    -- Auto Charge to target if out of range
    if settings.generalSettings.autoCharge then
        local targetDistance = API.GetTargetDistance()
        
        if targetDistance and targetDistance >= settings.generalSettings.chargeMinRange and 
           API.CanCast(self.spells.CHARGE) and API.IsSpellInRange(self.spells.CHARGE) then
            API.CastSpell(self.spells.CHARGE)
            return true
        end
    end
    
    -- Use Victory Rush for healing when available
    if settings.generalSettings.useVictoryRush then
        if API.PlayerHasBuff(self.spells.VICTORIOUS) and API.CanCast(self.spells.VICTORY_RUSH) then
            API.CastSpell(self.spells.VICTORY_RUSH)
            return true
        end
    end
    
    -- Handle low health defensives
    if settings.generalSettings.useDefensives then
        local healthPct = API.GetPlayerHealthPercent()
        
        -- Check for Rallying Cry conditions
        if healthPct <= settings.abilityControls.rallyCry.healthThreshold and 
           settings.abilityControls.rallyCry.enabled then
            
            -- Check if enough party members are present
            local partyMembersInRange = API.GetPartyMembersInRange(10)
            if partyMembersInRange >= settings.abilityControls.rallyCry.partyMembersThreshold and
               API.CanCast(self.spells.RALLYING_CRY) then
                API.CastSpell(self.spells.RALLYING_CRY)
                return true
            end
        end
        
        -- Check for Intimidating Shout as panic button
        if healthPct <= settings.abilityControls.intimidatingShout.panicButtonHealth and
           settings.abilityControls.intimidatingShout.panicButton and
           settings.abilityControls.intimidatingShout.enabled and
           API.CanCast(self.spells.INTIMIDATING_SHOUT) then
            API.CastSpell(self.spells.INTIMIDATING_SHOUT)
            return true
        end
    end
    
    -- Interrupt handling
    if settings.generalSettings.interruptEnabled then
        -- Get target casting info
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and API.CanCast(self.spells.PUMMEL) and 
           not API.IsSpellOnCooldown(self.spells.PUMMEL) then
            -- Check if spell should be interrupted
            local shouldInterrupt, delayInterrupt = AAC.ShouldUseAbility(
                self.spells.PUMMEL, 
                targetSpell,
                settings.generalSettings.interruptDelay
            )
            
            if shouldInterrupt then
                -- Delay interrupt based on settings
                C_Timer.After(delayInterrupt/1000, function()
                    API.CastSpell(self.spells.PUMMEL)
                end)
                return true
            end
        end
    end
    
    -- Spell Reflection handling for important enemy casts
    if settings.abilityControls.spellReflection.enabled then
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and API.CanCast(self.spells.SPELL_REFLECTION) and
           not API.IsSpellOnCooldown(self.spells.SPELL_REFLECTION) then
            
            -- Check if this is a priority spell to reflect
            local isPrioritySpell = false
            local prioritySpells = settings.abilityControls.spellReflection.prioritySpells
            
            if prioritySpells and prioritySpells ~= "" then
                for spellName in string.gmatch(prioritySpells, "([^,]+)") do
                    spellName = string.trim(spellName)
                    if targetSpell == spellName then
                        isPrioritySpell = true
                        break
                    end
                end
            end
            
            -- Check if cast is almost finished
            local castTimeRemaining = targetCastEnd - GetTime()
            if isPrioritySpell and castTimeRemaining <= settings.abilityControls.spellReflection.minimumCastTimeRemaining then
                API.CastSpell(self.spells.SPELL_REFLECTION)
                return true
            end
        end
    end
    
    return false
end

-- Register the class with the addon
addon:RegisterClass("WARRIOR", addon.Classes.Warrior)