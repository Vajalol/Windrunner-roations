------------------------------------------
-- WindrunnerRotations - Mage Class Module
-- Author: VortexQ8
------------------------------------------

-- Create base class node in addon table
local addonName, addon = ...
if not addon.Classes then addon.Classes = {} end
addon.Classes.Mage = {}

-- Reference commonly used modules
local API = addon.API
local ConfigRegistry = addon.Core.ConfigRegistry
local AAC = addon.Core.AdvancedAbilityControl

-- Constants
local MAGE_CLASS_ID = 8 -- WoW class ID for Mage

-- Initialize the class module
function addon.Classes.Mage:Initialize()
    self:InitializeVariables()
    self:RegisterSpells()
    self:RegisterSettings()
    self:LoadSpecModules()
    
    -- Print initialization message for debugging
    API.PrintDebug("Mage module initialized")
    
    return true
end

-- Initialize class-wide variables
function addon.Classes.Mage:InitializeVariables()
    self.specModules = {}
    self.activeSpec = API.GetActiveSpecID()
    
    -- Cache commonly used spell IDs 
    self.spells = {
        -- General Mage abilities
        ARCANE_INTELLECT = 1459,
        TIME_WARP = 80353,
        BLINK = 1953,
        SHIMMER = 212653,
        COUNTERSPELL = 2139,
        SPELLSTEAL = 30449,
        ICE_BLOCK = 45438,
        INVISIBILITY = 66,
        SLOW_FALL = 130,
        REMOVE_CURSE = 475,
        
        -- Defensive/utility abilities
        MIRROR_IMAGE = 55342,
        ALTER_TIME = 108978,
        ICE_BARRIER = 11426,
        BLAZING_BARRIER = 235313,
        PRISMATIC_BARRIER = 235450,
        
        -- Covenant abilities (if used by mage specs in retail)
        MIRRORS_OF_TORMENT = 314793,
        DEATHBORNE = 324220,
        RADIANT_SPARK = 307443,
        SHIFTED_POWER = 314791
    }
    
    return true
end

-- Register spell effects and handlers
function addon.Classes.Mage:RegisterSpells()
    -- Register general mage spells for tracking
    API.RegisterSpell(self.spells.ARCANE_INTELLECT)
    API.RegisterSpell(self.spells.TIME_WARP)
    API.RegisterSpell(self.spells.BLINK)
    API.RegisterSpell(self.spells.SHIMMER)
    API.RegisterSpell(self.spells.COUNTERSPELL)
    API.RegisterSpell(self.spells.SPELLSTEAL)
    API.RegisterSpell(self.spells.ICE_BLOCK)
    API.RegisterSpell(self.spells.INVISIBILITY)
    API.RegisterSpell(self.spells.MIRROR_IMAGE)
    API.RegisterSpell(self.spells.ALTER_TIME)
    
    -- Register spec barriers
    API.RegisterSpell(self.spells.ICE_BARRIER)
    API.RegisterSpell(self.spells.BLAZING_BARRIER)
    API.RegisterSpell(self.spells.PRISMATIC_BARRIER)
    
    -- Register covenant abilities if needed
    API.RegisterSpell(self.spells.MIRRORS_OF_TORMENT)
    API.RegisterSpell(self.spells.DEATHBORNE)
    API.RegisterSpell(self.spells.RADIANT_SPARK)
    API.RegisterSpell(self.spells.SHIFTED_POWER)
    
    return true
end

-- Register class-wide settings in the ConfigRegistry
function addon.Classes.Mage:RegisterSettings()
    -- Class-wide settings group
    ConfigRegistry:RegisterSettings("Mage", {
        generalSettings = {
            useBuffs = {
                displayName = "Auto Buff",
                description = "Automatically cast Arcane Intellect when missing",
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
                default = 35
            },
            interruptEnabled = {
                displayName = "Enable Interrupts",
                description = "Automatically interrupt enemy spellcasting with Counterspell",
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
            stealBuffs = {
                displayName = "Auto Spellsteal",
                description = "Automatically steal important enemy buffs",
                type = "toggle",
                default = true
            }
        },
        
        -- Advanced ability control settings
        abilityControls = {
            -- Time Warp controls
            timeWarp = AAC.RegisterAbility(self.spells.TIME_WARP, {
                enabled = true,
                useOnBossOnly = true,
                customTrigger = "BossEngage"
            }),
            
            -- Counterspell controls
            counterspell = AAC.RegisterAbility(self.spells.COUNTERSPELL, {
                enabled = true,
                excludedSpells = "",
                prioritySpells = "Healing Wave,Polymorph,Cyclone,Evocation",
                minimumCastTimeRemaining = 0.5
            }),
            
            -- Ice Block emergency controls
            iceBlock = AAC.RegisterAbility(self.spells.ICE_BLOCK, {
                enabled = true,
                healthThreshold = 15,
                clearDebuffs = true
            })
        }
    })
    
    return true
end

-- Load specialization modules
function addon.Classes.Mage:LoadSpecModules()
    -- Define spec IDs for Mage
    local FROST_SPEC_ID = 64
    local FIRE_SPEC_ID = 63
    local ARCANE_SPEC_ID = 62
    
    -- Try to load each specialization module
    local specs = {
        [FROST_SPEC_ID] = "Frost",
        [FIRE_SPEC_ID] = "Fire",
        [ARCANE_SPEC_ID] = "Arcane"
    }
    
    -- Load the modules
    for specID, specName in pairs(specs) do
        -- Try to load and initialize the module
        local success, errorMsg = pcall(function()
            -- Require the spec module
            local specFile = string.format("Classes.Mage.%s", specName)
            self.specModules[specID] = addon:RequireModule(specFile)
            
            -- Initialize if available
            if self.specModules[specID] and self.specModules[specID].Initialize then
                self.specModules[specID]:Initialize()
                API.PrintDebug("Loaded " .. specName .. " Mage module")
            end
        end)
        
        -- Log errors if module loading failed
        if not success then
            API.PrintError("Failed to load " .. specName .. " Mage module: " .. tostring(errorMsg))
        end
    end
    
    -- Register for spec change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function()
        self:OnSpecializationChanged()
    end)
    
    return true
end

-- Handle specialization changes
function addon.Classes.Mage:OnSpecializationChanged()
    local newSpecID = API.GetActiveSpecID()
    
    -- If spec changed, update active spec
    if newSpecID ~= self.activeSpec then
        API.PrintDebug("Mage specialization changed to: " .. tostring(newSpecID))
        self.activeSpec = newSpecID
        
        -- Call spec-specific handlers if they exist
        if self.specModules[newSpecID] and self.specModules[newSpecID].OnSpecializationChanged then
            self.specModules[newSpecID]:OnSpecializationChanged()
        end
    end
    
    return true
end

-- Main rotation function - delegates to the active spec
function addon.Classes.Mage:RunRotation()
    -- Check if we are a mage
    if API.GetPlayerClass() ~= MAGE_CLASS_ID then
        return false
    end
    
    -- Handle general mage logic first (buffs, defensives, etc.)
    self:HandleGeneralAbilities()
    
    -- Run the specialization-specific rotation
    local activeSpec = self.activeSpec
    if self.specModules[activeSpec] and self.specModules[activeSpec].RunRotation then
        return self.specModules[activeSpec]:RunRotation()
    end
    
    return false
end

-- Handle general mage abilities used across all specs
function addon.Classes.Mage:HandleGeneralAbilities()
    -- Skip if player is casting or channeling
    if API.IsPlayerCasting() or API.IsPlayerChanneling() then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("Mage")
    
    -- Auto buff with Arcane Intellect
    if settings.generalSettings.useBuffs then
        if not API.PlayerHasBuff(self.spells.ARCANE_INTELLECT) and API.CanCast(self.spells.ARCANE_INTELLECT) then
            API.CastSpell(self.spells.ARCANE_INTELLECT)
            return true
        end
    end
    
    -- Handle low health defensives
    if settings.generalSettings.useDefensives then
        local healthPct = API.GetPlayerHealthPercent()
        if healthPct <= settings.generalSettings.lowHealthDefensiveThreshold then
            -- Use appropriate barrier based on spec
            if API.GetActiveSpecID() == 63 and API.CanCast(self.spells.BLAZING_BARRIER) then
                -- Fire spec - use Blazing Barrier
                API.CastSpell(self.spells.BLAZING_BARRIER)
                return true
            elseif API.GetActiveSpecID() == 64 and API.CanCast(self.spells.ICE_BARRIER) then
                -- Frost spec - use Ice Barrier
                API.CastSpell(self.spells.ICE_BARRIER)
                return true
            elseif API.GetActiveSpecID() == 62 and API.CanCast(self.spells.PRISMATIC_BARRIER) then
                -- Arcane spec - use Prismatic Barrier
                API.CastSpell(self.spells.PRISMATIC_BARRIER)
                return true
            end
            
            -- Emergency Ice Block at very low health
            if healthPct <= settings.abilityControls.iceBlock.healthThreshold and 
               settings.abilityControls.iceBlock.enabled and
               API.CanCast(self.spells.ICE_BLOCK) then
                API.CastSpell(self.spells.ICE_BLOCK)
                return true
            end
        end
    end
    
    -- Interrupt handling
    if settings.generalSettings.interruptEnabled then
        -- Get target casting info
        local targetCasting, targetSpell, targetSpellID, targetCastEnd = API.IsTargetCasting()
        
        if targetCasting and API.CanCast(self.spells.COUNTERSPELL) and 
           not API.IsSpellOnCooldown(self.spells.COUNTERSPELL) then
            -- Check if spell should be interrupted
            local shouldInterrupt, delayInterrupt = AAC.ShouldUseAbility(
                self.spells.COUNTERSPELL, 
                targetSpell,
                settings.generalSettings.interruptDelay
            )
            
            if shouldInterrupt then
                -- Delay interrupt based on settings
                C_Timer.After(delayInterrupt/1000, function()
                    API.CastSpell(self.spells.COUNTERSPELL)
                end)
                return true
            end
        end
    end
    
    -- Spellsteal handling
    if settings.generalSettings.stealBuffs then
        local stealableBuffID = API.GetTargetStealableBuff()
        if stealableBuffID and API.CanCast(self.spells.SPELLSTEAL) then
            API.CastSpell(self.spells.SPELLSTEAL)
            return true
        end
    end
    
    return false
end

-- Register the class with the addon
addon:RegisterClass("MAGE", addon.Classes.Mage)