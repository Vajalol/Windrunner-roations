------------------------------------------
-- WindrunnerRotations - Advanced Ability Control
-- Author: VortexQ8
-- Handles advanced configuration for abilities
------------------------------------------

local addonName, addon = ...
addon.Core = addon.Core or {}
addon.Core.AdvancedAbilityControl = {}

local AAC = addon.Core.AdvancedAbilityControl
local API = addon.API
local registeredAbilities = {}
local interruptPriorities = {}
local defaultDelay = 200 -- ms

-- Register an ability for advanced control
function AAC.RegisterAbility(spellID, defaultSettings)
    if not spellID then
        API.PrintError("Invalid ability registration (missing spellID)")
        return nil
    end
    
    -- Create a unique ID for this ability
    local abilityID = "ability_" .. spellID
    
    -- Store the ability settings
    registeredAbilities[abilityID] = {
        spellID = spellID,
        defaultSettings = defaultSettings or {},
        customConditions = {}
    }
    
    -- Return the ability ID for referencing
    return abilityID
end

-- Register a custom condition function for an ability
function AAC.RegisterCustomCondition(abilityID, conditionName, conditionFunc)
    if not abilityID or not registeredAbilities[abilityID] then
        API.PrintError("Invalid ability ID for custom condition: " .. tostring(abilityID))
        return false
    end
    
    if not conditionName or not conditionFunc or type(conditionFunc) ~= "function" then
        API.PrintError("Invalid custom condition registration")
        return false
    end
    
    -- Store the custom condition
    registeredAbilities[abilityID].customConditions[conditionName] = conditionFunc
    
    API.PrintDebug("Registered custom condition: " .. conditionName .. " for ability: " .. abilityID)
    return true
end

-- Check if an ability should be used based on settings
function AAC.ShouldUseAbility(abilityID, context, randomDelay)
    if not abilityID or not registeredAbilities[abilityID] then
        -- If ability ID is a spell ID, look it up
        for id, data in pairs(registeredAbilities) do
            if data.spellID == abilityID then
                abilityID = id
                break
            end
        end
        
        -- If still not found, return false
        if not registeredAbilities[abilityID] then
            return false, 0
        end
    end
    
    local abilityData = registeredAbilities[abilityID]
    local settings = abilityData.defaultSettings
    context = context or {}
    
    -- Check if ability is enabled
    if settings.enabled ~= nil and not settings.enabled then
        return false, 0
    end
    
    -- Check all standard conditions
    
    -- Check health threshold if applicable
    if settings.healthThreshold and context.health and context.health > settings.healthThreshold then
        return false, 0
    end
    
    -- Check minimum enemies if applicable
    if settings.minEnemies and context.enemyCount and context.enemyCount < settings.minEnemies then
        return false, 0
    end
    
    -- Check burst mode requirement if applicable
    if settings.useDuringBurstOnly and context.burstMode ~= nil and not context.burstMode then
        return false, 0
    end
    
    -- Check for custom conditions
    for conditionName, conditionFunc in pairs(abilityData.customConditions) do
        if not conditionFunc(context) then
            return false, 0
        end
    end
    
    -- Calculate random delay if requested
    local delay = 0
    if randomDelay then
        delay = math.random(0, randomDelay or defaultDelay)
    end
    
    return true, delay
end

-- Register an interrupt priority
function AAC.RegisterInterruptPriority(spellName, priority)
    if not spellName or not priority then
        API.PrintError("Invalid interrupt priority registration")
        return false
    end
    
    -- Store the priority
    interruptPriorities[spellName] = priority
    
    API.PrintDebug("Registered interrupt priority: " .. spellName .. " = " .. priority)
    return true
end

-- Check if a spell should be interrupted based on priorities
function AAC.ShouldInterrupt(spellName, minPriority)
    if not spellName then
        return false, 0
    end
    
    local priority = interruptPriorities[spellName] or 0
    minPriority = minPriority or 0
    
    -- Check if priority meets threshold
    if priority >= minPriority then
        -- Calculate random delay
        local delay = math.random(0, defaultDelay)
        
        -- High priority spells get shorter delays
        if priority > 5 then
            delay = math.floor(delay / 2)
        end
        
        return true, delay
    end
    
    return false, 0
end

-- Find the best target for an ability based on settings
function AAC.FindBestTarget(abilityID, units, context)
    if not abilityID or not registeredAbilities[abilityID] or not units then
        return nil
    end
    
    local abilityData = registeredAbilities[abilityID]
    local settings = abilityData.defaultSettings
    context = context or {}
    
    -- Target priority (e.g., "tank,healer,dps")
    local targetPriority = settings.targetPriority or ""
    local priorities = {}
    
    -- Parse priority string
    for priority in targetPriority:gmatch("([^,]+)") do
        table.insert(priorities, priority:trim())
    end
    
    -- If no priorities, return nil
    if #priorities == 0 then
        return nil
    end
    
    -- Find best target based on priorities
    for _, priority in ipairs(priorities) do
        for _, unit in ipairs(units) do
            -- Check unit role matches priority
            local isMatch = false
            
            if priority == "self" and unit == "player" then
                isMatch = true
            elseif priority == "tank" and API.GetUnitRole(unit) == "TANK" then
                isMatch = true
            elseif priority == "healer" and API.GetUnitRole(unit) == "HEALER" then
                isMatch = true
            elseif priority == "dps" and API.GetUnitRole(unit) == "DAMAGER" then
                isMatch = true
            end
            
            -- Check health threshold if applicable
            if isMatch and settings.healthThreshold then
                local health = API.GetUnitHealthPercent(unit)
                isMatch = health <= settings.healthThreshold
            end
            
            -- Return first match
            if isMatch then
                return unit
            end
        end
    end
    
    return nil
end

-- Initialize the AAC system
function AAC.Initialize()
    -- Register default interrupt priorities
    AAC.RegisterInterruptPriority("Polymorph", 10)
    AAC.RegisterInterruptPriority("Fear", 9)
    AAC.RegisterInterruptPriority("Cyclone", 9)
    AAC.RegisterInterruptPriority("Hex", 9)
    AAC.RegisterInterruptPriority("Repentance", 8)
    AAC.RegisterInterruptPriority("Entangling Roots", 7)
    AAC.RegisterInterruptPriority("Chaos Bolt", 7)
    AAC.RegisterInterruptPriority("Pyroblast", 7)
    AAC.RegisterInterruptPriority("Greater Heal", 6)
    AAC.RegisterInterruptPriority("Flash Heal", 6)
    AAC.RegisterInterruptPriority("Mind Control", 10)
    AAC.RegisterInterruptPriority("Shadow Fury", 8)
    
    API.PrintDebug("Advanced Ability Control initialized")
    
    return true
end

-- Export the AAC module
return AAC