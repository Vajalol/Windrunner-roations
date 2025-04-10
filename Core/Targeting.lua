local addonName, WR = ...

-- Targeting module - handles target selection and validation
local Target = {}
WR.Target = Target

-- State
local state = {
    lastTargetCheck = 0,
    targetCheckInterval = 0.5, -- Check targets every 500ms
    validTarget = false,
    autoTargetEnabled = true,
    targetBlacklist = {},
}

-- Initialize the targeting system
function Target:Initialize()
    state.autoTargetEnabled = WR.Config:Get("enableAutoTargeting")
    state.targetCheckInterval = 0.5
end

-- Check if we have a valid target
function Target:HasValidTarget()
    if not UnitExists("target") then
        return false
    end
    
    if UnitIsDead("target") or UnitIsDeadOrGhost("target") then
        return false
    end
    
    if UnitCanAttack("player", "target") == false then
        return false
    end
    
    if self:IsTargetBlacklisted("target") then
        return false
    end
    
    return true
end

-- Get the best target from available options
function Target:GetBestTarget(range)
    range = range or 40 -- Default targeting range
    
    -- First check if current target is valid
    if self:HasValidTarget() then
        -- Check if current target is in range
        if WR.API:UnitDistance("target") <= range then
            return "target"
        end
    end
    
    -- Auto-targeting is disabled, don't find a new target
    if not state.autoTargetEnabled then
        return nil
    end
    
    -- Try to find a new target
    local bestTarget = nil
    local bestScore = -1
    local now = GetTime()
    
    -- Only check for new targets periodically to avoid performance issues
    if now - state.lastTargetCheck < state.targetCheckInterval then
        return nil
    end
    
    state.lastTargetCheck = now
    
    -- Get all units and find the best one
    local units = WR.API:GetUnits()
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and 
           not self:IsTargetBlacklisted(unit:GetToken()) then
            
            local distance = unit:GetDistance()
            if distance <= range then
                local score = self:ScoreTarget(unit, distance)
                if score > bestScore then
                    bestScore = score
                    bestTarget = unit:GetToken()
                end
            end
        end
    end
    
    -- If we found a good target, set it as current target
    if bestTarget and bestTarget ~= "target" then
        WR:Debug("Auto-targeting:", bestTarget)
        self:SetTarget(bestTarget)
    end
    
    return bestTarget
end

-- Score a target based on various factors
function Target:ScoreTarget(unit, distance)
    if not unit or not unit:Exists() then
        return -1
    end
    
    -- Base score starts with health percentage (lower is better)
    local healthPct = unit:HealthPercent()
    local score = 100 - healthPct
    
    -- Adjust score based on distance (closer is better)
    distance = distance or unit:GetDistance()
    score = score + (40 - distance) * 0.5
    
    -- Prioritize targets that are casting
    if unit:IsCasting() then
        score = score + 20
        
        -- Even higher priority for interruptible casts
        if unit:IsCastingInterruptible() then
            score = score + 20
        end
    end
    
    -- Prioritize targets that are currently targeting the player
    if unit:GetTarget() == UnitGUID("player") then
        score = score + 15
    end
    
    -- Check if the unit is a boss
    if unit:GetClassification() == "worldboss" or unit:GetClassification() == "rareelite" or unit:GetClassification() == "elite" then
        score = score + 30
    end
    
    -- Check if unit is in combat with us
    if UnitAffectingCombat(unit:GetToken()) then
        score = score + 10
    end
    
    return score
end

-- Set a unit as the current target
function Target:SetTarget(unit)
    -- Check if unit is valid
    if not UnitExists(unit) then
        return false
    end
    
    -- Don't change target if already targeting this unit
    if UnitIsUnit("target", unit) then
        return true
    end
    
    -- Set the target using Tinkr API if available
    if WR.API.ObjectManager and WR.API.ObjectManager.TargetUnit then
        WR.API.ObjectManager:TargetUnit(unit)
        return true
    end
    
    -- Fallback to normal targeting macro
    RunMacroText("/target " .. UnitName(unit))
    return true
end

-- Add a unit to the target blacklist
function Target:BlacklistTarget(unit, duration)
    if not unit then return false end
    
    local guid = UnitGUID(unit)
    if not guid then return false end
    
    duration = duration or 10 -- Default blacklist duration in seconds
    
    state.targetBlacklist[guid] = {
        expires = GetTime() + duration,
        name = UnitName(unit),
    }
    
    WR:Debug("Blacklisted target:", UnitName(unit), "for", duration, "seconds")
    
    return true
end

-- Check if a unit is blacklisted
function Target:IsTargetBlacklisted(unit)
    if not unit then return false end
    
    local guid = UnitGUID(unit)
    if not guid then return false end
    
    -- Check if in blacklist and not expired
    if state.targetBlacklist[guid] then
        if GetTime() < state.targetBlacklist[guid].expires then
            return true
        else
            -- Expired, remove from blacklist
            state.targetBlacklist[guid] = nil
        end
    end
    
    return false
end

-- Clear the target blacklist
function Target:ClearBlacklist()
    wipe(state.targetBlacklist)
    WR:Debug("Target blacklist cleared")
end

-- Enable or disable auto targeting
function Target:SetAutoTargeting(enabled)
    state.autoTargetEnabled = enabled
    WR.Config:Set("enableAutoTargeting", enabled)
    WR:Debug("Auto-targeting", enabled and "enabled" or "disabled")
end

-- Get auto targeting state
function Target:IsAutoTargetingEnabled()
    return state.autoTargetEnabled
end

-- Get the number of valid targets within a range
function Target:GetTargetCount(range)
    range = range or 8 -- Default AoE range
    
    local count = 0
    local units = WR.API:GetUnits()
    
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and 
           not self:IsTargetBlacklisted(unit:GetToken()) and
           unit:GetDistance() <= range then
            count = count + 1
        end
    end
    
    return count
end

-- Find a unit that needs to be interrupted
function Target:FindInterruptTarget(range, prioritySpells)
    range = range or 30 -- Default interrupt range
    prioritySpells = prioritySpells or {}
    
    local bestTarget = nil
    local bestPriority = 0
    local bestRemaining = 0
    
    local units = WR.API:GetUnits()
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and 
           unit:GetDistance() <= range and unit:IsCastingInterruptible() then
            
            local spellName = unit:CastingInfo()
            local spellEndTime = select(5, unit:CastingInfo()) or 0
            local remaining = (spellEndTime / 1000) - GetTime()
            
            -- Default priority for any interruptible cast
            local priority = 1
            
            -- Check if the spell is in our priority list
            if prioritySpells[spellName] then
                priority = prioritySpells[spellName]
            end
            
            -- Prioritize casts that are about to finish
            if remaining < 0.5 then
                priority = priority + 10
            end
            
            if priority > bestPriority or 
               (priority == bestPriority and remaining < bestRemaining) then
                bestPriority = priority
                bestRemaining = remaining
                bestTarget = unit:GetToken()
            end
        end
    end
    
    return bestTarget
end

-- Find a unit that needs to be dispelled
function Target:FindDispelTarget(dispelTypes, range, friendly)
    dispelTypes = dispelTypes or {} -- e.g., {"Magic", "Curse"}
    range = range or 40
    friendly = friendly or true -- True for friendly dispels, false for purges
    
    local bestTarget = nil
    local bestPriority = 0
    
    local units
    if friendly then
        -- For friendly dispels, check party/raid members
        units = {}
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                table.insert(units, "raid" .. i)
            end
        elseif IsInGroup() then
            for i = 1, GetNumGroupMembers() - 1 do
                table.insert(units, "party" .. i)
            end
            table.insert(units, "player")
        else
            table.insert(units, "player")
        end
    else
        -- For purges, check enemy units
        units = WR.API:GetUnits()
    end
    
    for _, unit in pairs(units) do
        local unitObj
        if type(unit) == "string" then
            unitObj = WR.API:GetUnit(unit)
        else
            unitObj = unit
            unit = unit:GetToken()
        end
        
        if unitObj and unitObj:Exists() and not unitObj:IsDead() and
           ((friendly and unitObj:IsFriend()) or (not friendly and unitObj:IsEnemy())) and
           unitObj:GetDistance() <= range then
            
            local auras = unitObj:GetAuras(friendly and "HARMFUL" or "HELPFUL")
            for _, aura in pairs(auras) do
                local dispelType = aura:GetDispelType()
                
                -- Check if we can dispel this type
                if dispelType and tContains(dispelTypes, dispelType) then
                    local priority = 1
                    
                    -- TODO: Add spell-specific priority logic here
                    
                    if priority > bestPriority then
                        bestPriority = priority
                        bestTarget = unit
                    end
                end
            end
        end
    end
    
    return bestTarget
end

-- Find the best healing target
function Target:FindHealingTarget(range)
    range = range or 40
    
    local bestTarget = nil
    local lowestHealth = 100
    
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            table.insert(units, "raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            table.insert(units, "party" .. i)
        end
        table.insert(units, "player")
    else
        table.insert(units, "player")
    end
    
    for _, unit in pairs(units) do
        local unitObj = WR.API:GetUnit(unit)
        if unitObj and unitObj:Exists() and not unitObj:IsDead() and
           unitObj:GetDistance() <= range then
            
            local healthPct = unitObj:HealthPercent()
            if healthPct < lowestHealth then
                lowestHealth = healthPct
                bestTarget = unit
            end
        end
    end
    
    return bestTarget, lowestHealth
end
