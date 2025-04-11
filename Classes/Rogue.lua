------------------------------------------
-- WindrunnerRotations - Rogue Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Rogue = {}

function Rogue:Initialize(addon)
    -- Store references to core addon components
    local API = addon.API
    local ConfigRegistry = addon.ConfigRegistry
    local AAC = addon.AdvancedAbilityControl
    
    -- Set up the Rogue class table
    addon.Classes.Rogue = {
        -- Will be populated with specialization modules
    }
    
    -- Load Rogue specialization modules
    local Assassination = addon:LoadModule("Classes.Rogue.Assassination")
    local Outlaw = addon:LoadModule("Classes.Rogue.Outlaw")
    local Subtlety = addon:LoadModule("Classes.Rogue.Subtlety")
    
    -- Add module references to the addon
    if Assassination then
        -- Inject dependencies
        Assassination.API = API
        Assassination.ConfigRegistry = ConfigRegistry
        Assassination.AAC = AAC
        Assassination.Rogue = addon.Classes.Rogue
        
        -- Initialize the module
        if Assassination:Initialize() then
            addon.Classes.Rogue.Assassination = Assassination
            API.PrintDebug("Assassination Rogue module loaded successfully")
        else
            API.PrintError("Failed to initialize Assassination Rogue module")
        end
    else
        API.PrintError("Failed to load Assassination Rogue module")
    end
    
    if Outlaw then
        -- Inject dependencies
        Outlaw.API = API
        Outlaw.ConfigRegistry = ConfigRegistry
        Outlaw.AAC = AAC
        Outlaw.Rogue = addon.Classes.Rogue
        
        -- Initialize the module
        if Outlaw:Initialize() then
            addon.Classes.Rogue.Outlaw = Outlaw
            API.PrintDebug("Outlaw Rogue module loaded successfully")
        else
            API.PrintError("Failed to initialize Outlaw Rogue module")
        end
    else
        API.PrintError("Failed to load Outlaw Rogue module")
    end
    
    if Subtlety then
        -- Inject dependencies
        Subtlety.API = API
        Subtlety.ConfigRegistry = ConfigRegistry
        Subtlety.AAC = AAC
        Subtlety.Rogue = addon.Classes.Rogue
        
        -- Initialize the module
        if Subtlety:Initialize() then
            addon.Classes.Rogue.Subtlety = Subtlety
            API.PrintDebug("Subtlety Rogue module loaded successfully")
        else
            API.PrintError("Failed to initialize Subtlety Rogue module")
        end
    else
        API.PrintError("Failed to load Subtlety Rogue module")
    end
    
    -- Register Rogue specialization functions with the module manager
    addon.ModuleManager:RegisterSpecialization(259, function() -- Assassination
        if addon.Classes.Rogue.Assassination then
            return addon.Classes.Rogue.Assassination:RunRotation()
        end
        return false
    end)
    
    addon.ModuleManager:RegisterSpecialization(260, function() -- Outlaw
        if addon.Classes.Rogue.Outlaw then
            return addon.Classes.Rogue.Outlaw:RunRotation()
        end
        return false
    end)
    
    addon.ModuleManager:RegisterSpecialization(261, function() -- Subtlety
        if addon.Classes.Rogue.Subtlety then
            return addon.Classes.Rogue.Subtlety:RunRotation()
        end
        return false
    end)
    
    -- Register for specialization change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            local currentSpec = API.GetSpecialization()
            
            if currentSpec == 1 then -- Assassination
                if addon.Classes.Rogue.Assassination then
                    addon.Classes.Rogue.Assassination:OnSpecializationChanged()
                end
            elseif currentSpec == 2 then -- Outlaw
                if addon.Classes.Rogue.Outlaw then
                    addon.Classes.Rogue.Outlaw:OnSpecializationChanged()
                end
            elseif currentSpec == 3 then -- Subtlety
                if addon.Classes.Rogue.Subtlety then
                    addon.Classes.Rogue.Subtlety:OnSpecializationChanged()
                end
            end
        end
    end)
    
    -- Common Rogue functionality and utility functions
    addon.Classes.Rogue.Utils = {
        -- Calculate the energy cost of an ability based on the current state
        CalculateEnergyCost = function(baseEnergyCost)
            local hasShadowFocus = (API.UnitHasBuff("player", 108209) or API.UnitHasBuff("player", 185422))
            local shadowFocusReduction = hasShadowFocus and 0.8 or 1.0
            
            return baseEnergyCost * shadowFocusReduction
        end,
        
        -- Calculate the effective damage multiplier from buffs/debuffs
        CalculateDamageMultiplier = function(targetGUID)
            local multiplier = 1.0
            
            -- Check for Find Weakness debuff
            if API.GetDebuffInfo(targetGUID, 91021) then
                multiplier = multiplier * 1.5 -- 50% increase from Find Weakness
            end
            
            -- Check for Symbols of Death buff
            if API.UnitHasBuff("player", 212283) then
                multiplier = multiplier * 1.25 -- 25% increase from Symbols of Death
            end
            
            -- Check for Shadow Dance with Dark Shadow talent
            if API.UnitHasBuff("player", 185422) and API.HasTalent(245687) then
                multiplier = multiplier * 1.3 -- 30% increase from Dark Shadow
            end
            
            return multiplier
        end,
        
        -- Check if a stealth ability such as Shadowstrike should be used
        ShouldUseStealthAbility = function()
            return API.IsStealthed() or API.UnitHasBuff("player", 185422) or API.UnitHasBuff("player", 115192)
        end
    }
    
    API.PrintDebug("Rogue class module loaded successfully")
    return true
end

return Rogue