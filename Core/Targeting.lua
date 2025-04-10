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
    state.targetModePreference = WR.Config:Get("targetModePreference") or "normal"
    state.interruptPrioritySpells = {}
    state.aoeTargetMemory = {} -- Remember good AoE targets between scans
    state.aoeTargetMemoryExpiration = 3.0 -- AoE target memory expires after 3 seconds
    
    self:RegisterInterruptPrioritySpells()
end

-- Register high-priority interrupt spells by dungeon/raid
function Target:RegisterInterruptPrioritySpells()
    -- Default high-priority interrupt spells (across all content)
    local defaultPrioritySpells = {
        -- High-priority healing spells
        ["Flash Heal"] = 80,
        ["Healing Wave"] = 70,
        ["Holy Light"] = 75,
        ["Regrowth"] = 70,
        ["Greater Heal"] = 80,
        ["Chain Heal"] = 85,
        ["Healing Rain"] = 85,
        ["Tranquility"] = 90,
        ["Divine Hymn"] = 90,
        ["Revival"] = 90,
        
        -- High-priority damage spells
        ["Shadow Bolt Volley"] = 60,
        ["Arcane Explosion"] = 60,
        ["Lightning Storm"] = 65,
        ["Fireball Barrage"] = 70,
        ["Shadow Blast"] = 65,
        ["Chaos Bolt"] = 75,
        ["Pyroblast"] = 70,
        
        -- High-priority crowd control spells
        ["Polymorph"] = 85,
        ["Fear"] = 80,
        ["Mind Control"] = 90,
        ["Hex"] = 85,
        ["Mass Entanglement"] = 80,
        ["Freezing Trap"] = 80,
        
        -- High-priority buff spells
        ["Power Word: Shield"] = 70,
        ["Bloodlust"] = 95,
        ["Heroism"] = 95,
        ["Time Warp"] = 95,
        ["Enrage"] = 80,
        ["Dark Empowerment"] = 85,
        ["Arcane Brilliance"] = 70
    }
    
    -- Load the default spells
    for spell, priority in pairs(defaultPrioritySpells) do
        state.interruptPrioritySpells[spell] = priority
    end
    
    -- Dungeon-specific priority spells could be loaded from the Dungeons module if available
    if WR.Dungeons and WR.Dungeons.GetInterruptPrioritySpells then
        local dungeonPrioritySpells = WR.Dungeons:GetInterruptPrioritySpells()
        if dungeonPrioritySpells then
            for spell, priority in pairs(dungeonPrioritySpells) do
                state.interruptPrioritySpells[spell] = priority
            end
        end
    end
    
    WR:Debug("Registered", #state.interruptPrioritySpells, "priority interrupt spells")
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
function Target:GetBestTarget(range, forceUpdate, targetMode)
    range = range or 40 -- Default targeting range
    targetMode = targetMode or "normal" -- Targeting mode: normal, aoe, cleave, execute, interrupt
    
    -- First check if current target is valid
    if self:HasValidTarget() and not forceUpdate then
        -- Check if current target is in range
        if WR.API:UnitDistance("target") <= range then
            -- For AoE modes, we might want to switch to a better target even if current is valid
            if targetMode == "normal" or targetMode == "execute" then
                return "target"
            end
        end
    end
    
    -- Auto-targeting is disabled, don't find a new target
    if not state.autoTargetEnabled and not forceUpdate then
        return nil
    end
    
    -- Try to find a new target
    local bestTarget = nil
    local bestScore = -1
    local now = GetTime()
    
    -- Only check for new targets periodically to avoid performance issues (unless forced)
    if not forceUpdate and now - state.lastTargetCheck < state.targetCheckInterval then
        return nil
    end
    
    state.lastTargetCheck = now
    
    -- Target mode adjustments
    local scoreModifier = function(unit, score)
        -- Base score from regular scoring function
        if targetMode == "aoe" then
            -- For AoE, prioritize groups of enemies
            local nearbyCount = 0
            local unitPos = unit:GetPosition()
            
            if unitPos then
                -- Count enemies near this unit
                local units = WR.API:GetUnits()
                for _, otherUnit in pairs(units) do
                    if otherUnit:Exists() and not otherUnit:IsDead() and otherUnit:IsEnemy() and
                       otherUnit:GetToken() ~= unit:GetToken() and
                       not self:IsTargetBlacklisted(otherUnit:GetToken()) then
                        
                        local otherPos = otherUnit:GetPosition()
                        if otherPos and self:GetDistanceBetweenPositions(unitPos, otherPos) <= 8 then
                            nearbyCount = nearbyCount + 1
                        end
                    end
                end
                
                -- Significant bonus for units with many nearby enemies
                score = score + (nearbyCount * 15)
            end
            
        elseif targetMode == "cleave" then
            -- For cleave, prioritize targets that are near our current target
            if UnitExists("target") then
                local targetPos = WR.API:GetUnitPosition("target")
                local unitPos = unit:GetPosition()
                
                if targetPos and unitPos then
                    local distanceToTarget = self:GetDistanceBetweenPositions(targetPos, unitPos)
                    if distanceToTarget <= 8 then
                        -- Higher score for units close to our current target
                        score = score + ((8 - distanceToTarget) * 10)
                    else
                        -- Significant penalty for units far from our current target
                        score = score - 50
                    end
                end
            end
            
        elseif targetMode == "execute" then
            -- For execute phase, heavily prioritize low health targets
            local healthPct = unit:HealthPercent()
            if healthPct < 20 then
                -- Massive bonus for execute-range targets
                score = score + 200 + ((20 - healthPct) * 5)
            else
                -- Significant penalty for non-execute targets
                score = score - 100
            end
            
        elseif targetMode == "interrupt" then
            -- For interrupt mode, only consider interruptible casters
            if unit:IsCastingInterruptible() then
                -- Get cast remaining time
                local spellName, _, _, startTimeMS, endTimeMS = unit:CastingInfo()
                if endTimeMS then
                    local remaining = (endTimeMS / 1000) - GetTime()
                    if remaining > 0 then
                        -- Prioritize casts that are about to finish
                        if remaining < 1.0 then
                            score = score + 300 -- Very high priority for casts about to finish
                        else
                            score = score + 200 -- High priority for any interruptible cast
                        end
                        
                        -- If we have a priority spell list, check it
                        if state.interruptPrioritySpells and state.interruptPrioritySpells[spellName] then
                            score = score + (state.interruptPrioritySpells[spellName] * 10)
                        end
                    end
                end
            else
                -- Significant penalty for non-interruptible targets
                score = score - 200
            end
        end
        
        return score
    end
    
    -- Get all units and find the best one
    local units = WR.API:GetUnits()
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and 
           not self:IsTargetBlacklisted(unit:GetToken()) then
            
            local distance = unit:GetDistance()
            if distance <= range then
                -- Get base score
                local score = self:ScoreTarget(unit, distance)
                
                -- Apply mode-specific adjustments
                score = scoreModifier(unit, score)
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = unit:GetToken()
                end
            end
        end
    end
    
    -- If we found a good target, set it as current target
    if bestTarget and (bestTarget ~= "target" or forceUpdate) then
        WR:Debug("Auto-targeting:", bestTarget, "(Mode: " .. targetMode .. ")")
        self:SetTarget(bestTarget)
    end
    
    return bestTarget
end

-- Helper function to calculate distance between two position tables
function Target:GetDistanceBetweenPositions(pos1, pos2)
    if not pos1 or not pos2 then return 999 end
    
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Score a target based on various factors with advanced prioritization
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
    local classification = unit:GetClassification()
    if classification == "worldboss" then
        score = score + 50
    elseif classification == "rareelite" then
        score = score + 40
    elseif classification == "elite" then
        score = score + 30
    elseif classification == "rare" then
        score = score + 25
    end
    
    -- Check if unit is in combat with us
    if UnitAffectingCombat(unit:GetToken()) then
        score = score + 10
    end
    
    -- Prioritize targets with important debuffs (e.g. damage amplification)
    local importantDebuffs = {
        -- Common damage amplification debuffs
        ["Touch of Karma"] = 25,
        ["Colossus Smash"] = 20,
        ["Vendetta"] = 20,
        ["Doom Winds"] = 20,
        ["Vulnerability"] = 15,
        -- Class-specific damage debuffs would be added here
    }
    
    for debuffName, debuffScore in pairs(importantDebuffs) do
        if WR.API:UnitHasAura(unit:GetToken(), debuffName, "HARMFUL") then
            score = score + debuffScore
        end
    end
    
    -- Check for covenant/spec-specific buffs that increase damage
    local damageBuffs = {
        ["Sinful Brand"] = 15,
        ["Recklessness"] = 15,
        ["Avenging Wrath"] = 15,
        ["Celestial Alignment"] = 15,
        -- Class-specific damage buffs would be added here
    }
    
    for buffName, buffScore in pairs(damageBuffs) do
        if WR.API:UnitHasAura("player", buffName, "HELPFUL") then
            -- If player has damage amplification, prioritize low health targets even more
            score = score + ((100 - healthPct) * 0.2) + buffScore
        end
    end
    
    -- Adjust score based on custom dungeon priorities if available
    if WR.Dungeons and WR.Dungeons.GetEnemyPriority then
        local enemyID = unit:GetCreatureID()
        if enemyID then
            local priority = WR.Dungeons:GetEnemyPriority(enemyID)
            if priority then
                score = score + priority * 10 -- Scale priority by 10
            end
        end
    end
    
    -- Adjust for time-to-live
    if WR.Combat and WR.Combat.GetTimeToLive then
        local ttl = WR.Combat:GetTimeToLive(unit:GetToken())
        if ttl and ttl > 0 and ttl < 5 then
            -- Reduce score for enemies about to die unless they're high value
            if classification ~= "worldboss" and classification ~= "rareelite" then
                score = score - ((5 - ttl) * 10)
            end
        end
    end
    
    -- If we have our burst cooldowns active, prioritize higher health targets for efficient use
    if WR.Rotation and WR.Rotation:ShouldUseCooldowns() then
        if healthPct > 80 then
            score = score + 15 -- Better to use cooldowns on high health targets
        end
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

-- Find the best AoE anchor target for the given range
function Target:FindBestAoETarget(range, targetCount)
    range = range or 8 -- Default AoE range
    targetCount = targetCount or 3 -- Minimum targets for a valid AoE cluster
    
    local bestTarget = nil
    local bestCount = 0
    local now = GetTime()
    
    -- First check our AoE target memory to avoid unnecessary scanning
    local bestMemoryTarget = nil
    local bestMemoryScore = 0
    
    for guid, data in pairs(state.aoeTargetMemory) do
        -- Skip expired entries
        if now - data.timestamp > state.aoeTargetMemoryExpiration then
            state.aoeTargetMemory[guid] = nil
        else
            -- If we have a recent and good enough anchor, use that
            if data.count >= targetCount and data.count > bestMemoryScore then
                bestMemoryScore = data.count
                bestMemoryTarget = data.unit
            end
        end
    end
    
    -- If we found a valid target in memory and it still exists, use it
    if bestMemoryTarget and UnitExists(bestMemoryTarget) and 
       not UnitIsDead(bestMemoryTarget) and 
       not self:IsTargetBlacklisted(bestMemoryTarget) then
        -- Verify it's still in range
        local distance = WR.API:UnitDistance(bestMemoryTarget)
        if distance and distance <= range then
            return bestMemoryTarget, bestMemoryScore
        end
    end
    
    -- No valid target in memory, scan for a new one
    local units = WR.API:GetUnits()
    
    -- Get all valid enemy units first
    local validUnits = {}
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and 
           not self:IsTargetBlacklisted(unit:GetToken()) then
            local distance = unit:GetDistance()
            if distance <= range then
                table.insert(validUnits, unit)
            end
        end
    end
    
    -- Test each unit as a potential AoE anchor
    for _, anchorUnit in ipairs(validUnits) do
        local anchorPosition = anchorUnit:GetPosition()
        if anchorPosition then
            local enemiesNearAnchor = 1 -- Count the anchor itself
            
            -- Count other enemies near this anchor
            for _, otherUnit in ipairs(validUnits) do
                if otherUnit:GetToken() ~= anchorUnit:GetToken() then
                    local otherPosition = otherUnit:GetPosition()
                    if otherPosition and 
                       self:GetDistanceBetweenPositions(anchorPosition, otherPosition) <= range then
                        enemiesNearAnchor = enemiesNearAnchor + 1
                    end
                end
            end
            
            -- Update best target if this one has more nearby enemies
            if enemiesNearAnchor > bestCount then
                bestCount = enemiesNearAnchor
                bestTarget = anchorUnit:GetToken()
            end
        end
    end
    
    -- If we found a good AoE anchor, save it in memory
    if bestTarget and bestCount >= targetCount then
        state.aoeTargetMemory[UnitGUID(bestTarget)] = {
            unit = bestTarget,
            count = bestCount,
            timestamp = now
        }
    end
    
    return bestTarget, bestCount
end

-- Find targets within cleave range of a specific unit
function Target:GetUnitsInCleaveRange(anchorUnit, range)
    if not anchorUnit or not UnitExists(anchorUnit) then
        anchorUnit = "target"
    end
    
    range = range or 8 -- Default cleave range
    
    -- If the anchor unit doesn't exist, return empty table
    if not UnitExists(anchorUnit) then
        return {}
    end
    
    local anchorPosition = WR.API:GetUnitPosition(anchorUnit)
    if not anchorPosition then
        return {}
    end
    
    local cleaveUnits = {}
    local units = WR.API:GetUnits()
    
    for _, unit in pairs(units) do
        if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and 
           not self:IsTargetBlacklisted(unit:GetToken()) and
           unit:GetToken() ~= anchorUnit then
            
            local unitPosition = unit:GetPosition()
            if unitPosition and 
               self:GetDistanceBetweenPositions(anchorPosition, unitPosition) <= range then
                table.insert(cleaveUnits, unit:GetToken())
            end
        end
    end
    
    return cleaveUnits
end

-- Set targeting mode preference
function Target:SetTargetingMode(mode)
    local validModes = {
        ["normal"] = true,
        ["aoe"] = true,
        ["cleave"] = true,
        ["execute"] = true,
        ["interrupt"] = true,
        ["auto"] = true -- Auto will select based on combat situation
    }
    
    if validModes[mode] then
        state.targetModePreference = mode
        WR.Config:Set("targetModePreference", mode)
        WR:Debug("Target mode set to:", mode)
        return true
    else
        WR:Debug("Invalid target mode:", mode)
        return false
    end
end

-- Get the current targeting mode (or calculate it if set to auto)
function Target:GetTargetingMode()
    if state.targetModePreference ~= "auto" then
        return state.targetModePreference
    end
    
    -- Auto mode - determine best mode based on situation
    local mode = "normal"
    
    -- Check for AoE situation
    local aoeTarget, aoeCount = self:FindBestAoETarget(8, 3)
    if aoeCount >= 3 then
        mode = "aoe"
    elseif aoeCount == 2 then
        mode = "cleave"
    end
    
    -- Check for execute phase - if target or player has low health
    if UnitExists("target") and not UnitIsDead("target") then
        local targetHealth = UnitHealth("target") / UnitHealthMax("target") * 100
        if targetHealth < 20 then
            mode = "execute"
        end
    end
    
    -- Check for interruptible casts
    local interruptTarget = self:FindInterruptTarget(30)
    if interruptTarget then
        mode = "interrupt"
    end
    
    return mode
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
