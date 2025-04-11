------------------------------------------
-- WindrunnerRotations - Paladin Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Paladin = {}

function Paladin:Initialize(addon)
    -- Store references to core addon components
    local API = addon.API
    local ConfigRegistry = addon.ConfigRegistry
    local AAC = addon.AdvancedAbilityControl
    
    -- Set up the Paladin class table
    addon.Classes.Paladin = {
        -- Will be populated with specialization modules
    }
    
    -- Load Paladin specialization modules
    local Holy = addon:LoadModule("Classes.Paladin.Holy")
    local Protection = addon:LoadModule("Classes.Paladin.Protection")
    local Retribution = addon:LoadModule("Classes.Paladin.Retribution")
    
    -- Add module references to the addon
    if Holy then
        -- Inject dependencies
        Holy.API = API
        Holy.ConfigRegistry = ConfigRegistry
        Holy.AAC = AAC
        Holy.Paladin = addon.Classes.Paladin
        
        -- Initialize the module
        if Holy:Initialize() then
            addon.Classes.Paladin.Holy = Holy
            API.PrintDebug("Holy Paladin module loaded successfully")
        else
            API.PrintError("Failed to initialize Holy Paladin module")
        end
    else
        API.PrintError("Failed to load Holy Paladin module")
    end
    
    if Protection then
        -- Inject dependencies
        Protection.API = API
        Protection.ConfigRegistry = ConfigRegistry
        Protection.AAC = AAC
        Protection.Paladin = addon.Classes.Paladin
        
        -- Initialize the module
        if Protection:Initialize() then
            addon.Classes.Paladin.Protection = Protection
            API.PrintDebug("Protection Paladin module loaded successfully")
        else
            API.PrintError("Failed to initialize Protection Paladin module")
        end
    else
        API.PrintError("Failed to load Protection Paladin module")
    end
    
    if Retribution then
        -- Inject dependencies
        Retribution.API = API
        Retribution.ConfigRegistry = ConfigRegistry
        Retribution.AAC = AAC
        Retribution.Paladin = addon.Classes.Paladin
        
        -- Initialize the module
        if Retribution:Initialize() then
            addon.Classes.Paladin.Retribution = Retribution
            API.PrintDebug("Retribution Paladin module loaded successfully")
        else
            API.PrintError("Failed to initialize Retribution Paladin module")
        end
    else
        API.PrintError("Failed to load Retribution Paladin module")
    end
    
    -- Register Paladin specialization functions with the module manager
    addon.ModuleManager:RegisterSpecialization(65, function() -- Holy
        if addon.Classes.Paladin.Holy then
            return addon.Classes.Paladin.Holy:RunRotation()
        end
        return false
    end)
    
    addon.ModuleManager:RegisterSpecialization(66, function() -- Protection
        if addon.Classes.Paladin.Protection then
            return addon.Classes.Paladin.Protection:RunRotation()
        end
        return false
    end)
    
    addon.ModuleManager:RegisterSpecialization(70, function() -- Retribution
        if addon.Classes.Paladin.Retribution then
            return addon.Classes.Paladin.Retribution:RunRotation()
        end
        return false
    end)
    
    -- Register for specialization change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            local currentSpec = API.GetSpecialization()
            
            if currentSpec == 1 then -- Holy
                if addon.Classes.Paladin.Holy then
                    addon.Classes.Paladin.Holy:OnSpecializationChanged()
                end
            elseif currentSpec == 2 then -- Protection
                if addon.Classes.Paladin.Protection then
                    addon.Classes.Paladin.Protection:OnSpecializationChanged()
                end
            elseif currentSpec == 3 then -- Retribution
                if addon.Classes.Paladin.Retribution then
                    addon.Classes.Paladin.Retribution:OnSpecializationChanged()
                end
            end
        end
    end)
    
    -- Common Paladin functionality and utility functions
    addon.Classes.Paladin.Utils = {
        -- Calculate the effect of Judgment debuff on Holy Power abilities
        ApplyJudgmentDebuff = function(damage, targetGUID)
            if API.GetDebuffInfo(targetGUID, 197277) then -- Judgment debuff
                return damage * 1.25 -- 25% increase from Judgment
            end
            return damage
        end,
        
        -- Check if Avenging Wrath or similar buff is active
        IsAvengingWrathActive = function()
            return API.UnitHasBuff("player", 31884) or -- Avenging Wrath
                   API.UnitHasBuff("player", 216331)   -- Avenging Crusader
        end,
        
        -- Calculate Holy Power consumption for an ability
        CalculateHolyPowerCost = function(baseHolyPower)
            local divinePurposeActive = API.UnitHasBuff("player", 223819) -- Divine Purpose
            if divinePurposeActive then
                return 0 -- No Holy Power cost
            end
            return baseHolyPower
        end
    }
    
    API.PrintDebug("Paladin class module loaded successfully")
    return true
end

return Paladin