------------------------------------------
-- WindrunnerRotations - Monk Class Module
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local Monk = {}

function Monk:Initialize(addon)
    -- Store references to core addon components
    local API = addon.API
    local ConfigRegistry = addon.ConfigRegistry
    local AAC = addon.AdvancedAbilityControl
    
    -- Set up the Monk class table
    addon.Classes.Monk = {
        -- Will be populated with specialization modules
    }
    
    -- Load Monk specialization modules
    local Brewmaster = addon:LoadModule("Classes.Monk.Brewmaster")
    local Windwalker = addon:LoadModule("Classes.Monk.Windwalker")
    local Mistweaver = addon:LoadModule("Classes.Monk.Mistweaver")
    
    -- Add module references to the addon
    if Brewmaster then
        -- Inject dependencies
        Brewmaster.API = API
        Brewmaster.ConfigRegistry = ConfigRegistry
        Brewmaster.AAC = AAC
        Brewmaster.Monk = addon.Classes.Monk
        
        -- Initialize the module
        if Brewmaster:Initialize() then
            addon.Classes.Monk.Brewmaster = Brewmaster
            API.PrintDebug("Brewmaster Monk module loaded successfully")
        else
            API.PrintError("Failed to initialize Brewmaster Monk module")
        end
    else
        API.PrintError("Failed to load Brewmaster Monk module")
    end
    
    if Windwalker then
        -- Inject dependencies
        Windwalker.API = API
        Windwalker.ConfigRegistry = ConfigRegistry
        Windwalker.AAC = AAC
        Windwalker.Monk = addon.Classes.Monk
        
        -- Initialize the module
        if Windwalker:Initialize() then
            addon.Classes.Monk.Windwalker = Windwalker
            API.PrintDebug("Windwalker Monk module loaded successfully")
        else
            API.PrintError("Failed to initialize Windwalker Monk module")
        end
    else
        API.PrintError("Failed to load Windwalker Monk module")
    end
    
    if Mistweaver then
        -- Inject dependencies
        Mistweaver.API = API
        Mistweaver.ConfigRegistry = ConfigRegistry
        Mistweaver.AAC = AAC
        Mistweaver.Monk = addon.Classes.Monk
        
        -- Initialize the module
        if Mistweaver:Initialize() then
            addon.Classes.Monk.Mistweaver = Mistweaver
            API.PrintDebug("Mistweaver Monk module loaded successfully")
        else
            API.PrintError("Failed to initialize Mistweaver Monk module")
        end
    else
        API.PrintError("Failed to load Mistweaver Monk module")
    end
    
    -- Register Monk specialization functions with the module manager
    addon.ModuleManager:RegisterSpecialization(268, function() -- Brewmaster
        if addon.Classes.Monk.Brewmaster then
            return addon.Classes.Monk.Brewmaster:RunRotation()
        end
        return false
    end)
    
    addon.ModuleManager:RegisterSpecialization(269, function() -- Windwalker
        if addon.Classes.Monk.Windwalker then
            return addon.Classes.Monk.Windwalker:RunRotation()
        end
        return false
    end)
    
    addon.ModuleManager:RegisterSpecialization(270, function() -- Mistweaver
        if addon.Classes.Monk.Mistweaver then
            return addon.Classes.Monk.Mistweaver:RunRotation()
        end
        return false
    end)
    
    -- Register for specialization change events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            local currentSpec = API.GetSpecialization()
            
            if currentSpec == 1 then -- Brewmaster
                if addon.Classes.Monk.Brewmaster then
                    addon.Classes.Monk.Brewmaster:OnSpecializationChanged()
                end
            elseif currentSpec == 2 then -- Windwalker
                if addon.Classes.Monk.Windwalker then
                    addon.Classes.Monk.Windwalker:OnSpecializationChanged()
                end
            elseif currentSpec == 3 then -- Mistweaver
                if addon.Classes.Monk.Mistweaver then
                    addon.Classes.Monk.Mistweaver:OnSpecializationChanged()
                end
            end
        end
    end)
    
    -- Common Monk functionality and utility functions
    addon.Classes.Monk.Utils = {
        -- Calculate the value of Mastery: Gust of Mists for Mistweaver
        CalculateGustOfMistsHealing = function(baseHealing)
            local masteryPercentage = API.GetMasteryPercentage()
            return baseHealing * (1 + (masteryPercentage / 100))
        end,
        
        -- Check if the player has enough Chi
        HasEnoughChi = function(requiredChi)
            local currentChi = API.GetPlayerPower()
            return currentChi >= requiredChi
        end,
        
        -- Check if a target has Rising Sun Kick debuff (Windwalker)
        HasRisingSunKickDebuff = function(unit)
            return API.UnitHasDebuff(unit, 107428) -- Rising Sun Kick debuff
        end
    }
    
    API.PrintDebug("Monk class module loaded successfully")
    return true
end

return Monk