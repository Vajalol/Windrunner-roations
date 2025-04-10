local addonName, WR = ...

-- Condition module - handles the evaluation of conditions for spells and actions
local Condition = {}
WR.Condition = Condition

-- State
local state = {
    evaluationCount = 0,
    conditions = {},  -- Predefined conditions
    customConditions = {}, -- User-defined conditions
    conditionCaches = {}, -- Cache of condition results to improve performance
    lastCacheClear = 0,
    cacheLifetime = 0.1, -- Cache results for 100ms
}

-- Initialize the condition module
function Condition:Initialize()
    -- Register predefined conditions
    self:RegisterPredefinedConditions()
    
    -- Create a frame for regular cache clearing
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        if now - state.lastCacheClear > state.cacheLifetime then
            Condition:ClearCache()
            state.lastCacheClear = now
        end
    end)
    
    WR:Debug("Condition module initialized")
end

-- Register a condition
function Condition:RegisterCondition(name, evaluatorFunc, description)
    if type(name) ~= "string" or type(evaluatorFunc) ~= "function" then
        WR:Debug("Failed to register condition - invalid parameters")
        return false
    end
    
    state.conditions[name] = {
        evaluator = evaluatorFunc,
        description = description or "No description",
    }
    
    WR:Debug("Registered condition:", name)
    return true
end

-- Register a custom condition
function Condition:RegisterCustomCondition(name, evaluatorFunc, description)
    if type(name) ~= "string" or type(evaluatorFunc) ~= "function" then
        WR:Debug("Failed to register custom condition - invalid parameters")
        return false
    end
    
    state.customConditions[name] = {
        evaluator = evaluatorFunc,
        description = description or "Custom condition",
    }
    
    WR:Debug("Registered custom condition:", name)
    return true
end

-- Clear the condition cache
function Condition:ClearCache()
    wipe(state.conditionCaches)
end

-- Evaluate a condition
function Condition:Evaluate(conditionName, ...)
    state.evaluationCount = state.evaluationCount + 1
    
    -- Check if we have this condition
    local condition = state.conditions[conditionName] or state.customConditions[conditionName]
    if not condition then
        WR:Debug("Unknown condition:", conditionName)
        return false
    end
    
    -- Generate cache key based on the condition name and arguments
    local cacheKey = conditionName
    local args = {...}
    for i, arg in ipairs(args) do
        if type(arg) == "string" or type(arg) == "number" then
            cacheKey = cacheKey .. "_" .. tostring(arg)
        end
    end
    
    -- Check if the result is cached
    if state.conditionCaches[cacheKey] then
        return state.conditionCaches[cacheKey]
    end
    
    -- Evaluate the condition
    local success, result = pcall(condition.evaluator, ...)
    if not success then
        WR:Debug("Error evaluating condition", conditionName, result)
        return false
    end
    
    -- Cache the result
    state.conditionCaches[cacheKey] = result
    
    return result
end

-- Evaluate a complex condition expression
function Condition:EvaluateExpression(expression, context)
    if type(expression) == "function" then
        -- Direct function evaluation
        local success, result = pcall(expression, context)
        return success and result or false
    elseif type(expression) == "string" then
        -- Named condition
        return self:Evaluate(expression, context)
    elseif type(expression) == "table" then
        -- Composite condition
        if expression.type == "AND" and expression.conditions then
            -- AND - all conditions must be true
            for _, subCondition in ipairs(expression.conditions) do
                if not self:EvaluateExpression(subCondition, context) then
                    return false
                end
            end
            return true
        elseif expression.type == "OR" and expression.conditions then
            -- OR - at least one condition must be true
            for _, subCondition in ipairs(expression.conditions) do
                if self:EvaluateExpression(subCondition, context) then
                    return true
                end
            end
            return false
        elseif expression.type == "NOT" and expression.condition then
            -- NOT - invert the result
            return not self:EvaluateExpression(expression.condition, context)
        elseif expression.condition and expression.args then
            -- Named condition with args
            return self:Evaluate(expression.condition, unpack(expression.args))
        end
    end
    
    -- Default
    return false
end

-- Create a 'AND' composite condition
function Condition:AND(...)
    local conditions = {...}
    return {
        type = "AND",
        conditions = conditions
    }
end

-- Create a 'OR' composite condition
function Condition:OR(...)
    local conditions = {...}
    return {
        type = "OR",
        conditions = conditions
    }
end

-- Create a 'NOT' composite condition
function Condition:NOT(condition)
    return {
        type = "NOT",
        condition = condition
    }
end

-- Register predefined conditions
function Condition:RegisterPredefinedConditions()
    -- Player state conditions
    self:RegisterCondition("player.health.percent.below", 
        function(threshold) 
            return WR.API:UnitHealthPercent("player") < threshold 
        end,
        "Player health percentage is below threshold")
    
    self:RegisterCondition("player.health.percent.above", 
        function(threshold) 
            return WR.API:UnitHealthPercent("player") > threshold 
        end,
        "Player health percentage is above threshold")
    
    self:RegisterCondition("player.power.percent.below", 
        function(threshold, powerType) 
            return WR.API:UnitPowerPercent("player", powerType) < threshold 
        end,
        "Player power percentage is below threshold")
    
    self:RegisterCondition("player.power.percent.above", 
        function(threshold, powerType) 
            return WR.API:UnitPowerPercent("player", powerType) > threshold 
        end,
        "Player power percentage is above threshold")
    
    self:RegisterCondition("player.buff.active", 
        function(buffName) 
            return WR.API:UnitHasAura("player", buffName, "HELPFUL") 
        end,
        "Player has the specified buff")
    
    self:RegisterCondition("player.buff.stacks", 
        function(buffName, stacks) 
            local aura = WR.API:UnitAura("player", buffName, "HELPFUL")
            return aura and aura:GetStacks() >= stacks
        end,
        "Player has at least the specified number of buff stacks")
    
    self:RegisterCondition("player.buff.remains", 
        function(buffName, seconds) 
            local aura = WR.API:UnitAura("player", buffName, "HELPFUL")
            if not aura then return false end
            local expireTime = aura:GetExpireTime()
            if not expireTime then return true end -- Permanent buff
            return (expireTime - GetTime()) >= seconds
        end,
        "Player buff has at least the specified time remaining")
    
    self:RegisterCondition("player.debuff.active", 
        function(debuffName) 
            return WR.API:UnitHasAura("player", debuffName, "HARMFUL") 
        end,
        "Player has the specified debuff")
    
    self:RegisterCondition("player.moving", 
        function() 
            return WR.API:IsMoving() 
        end,
        "Player is moving")
    
    self:RegisterCondition("player.incombat", 
        function() 
            return WR.API:InCombat() 
        end,
        "Player is in combat")
    
    -- Target state conditions
    self:RegisterCondition("target.exists", 
        function() 
            return WR.API:UnitExists("target") 
        end,
        "Target exists")
    
    self:RegisterCondition("target.health.percent.below", 
        function(threshold) 
            return WR.API:UnitExists("target") and WR.API:UnitHealthPercent("target") < threshold 
        end,
        "Target health percentage is below threshold")
    
    self:RegisterCondition("target.health.percent.above", 
        function(threshold) 
            return WR.API:UnitExists("target") and WR.API:UnitHealthPercent("target") > threshold 
        end,
        "Target health percentage is above threshold")
    
    self:RegisterCondition("target.debuff.active", 
        function(debuffName) 
            return WR.API:UnitExists("target") and WR.API:UnitHasAura("target", debuffName, "HARMFUL") 
        end,
        "Target has the specified debuff")
    
    self:RegisterCondition("target.debuff.remains", 
        function(debuffName, seconds) 
            if not WR.API:UnitExists("target") then return false end
            local aura = WR.API:UnitAura("target", debuffName, "HARMFUL")
            if not aura then return false end
            local expireTime = aura:GetExpireTime()
            if not expireTime then return true end -- Permanent debuff
            return (expireTime - GetTime()) >= seconds
        end,
        "Target debuff has at least the specified time remaining")
    
    self:RegisterCondition("target.debuff.stacks", 
        function(debuffName, stacks) 
            if not WR.API:UnitExists("target") then return false end
            local aura = WR.API:UnitAura("target", debuffName, "HARMFUL")
            return aura and aura:GetStacks() >= stacks
        end,
        "Target has at least the specified number of debuff stacks")
    
    self:RegisterCondition("target.distance.below", 
        function(distance) 
            return WR.API:UnitExists("target") and WR.API:UnitDistance("target") < distance 
        end,
        "Target is closer than the specified distance")
    
    self:RegisterCondition("target.distance.above", 
        function(distance) 
            return WR.API:UnitExists("target") and WR.API:UnitDistance("target") > distance 
        end,
        "Target is further than the specified distance")
    
    self:RegisterCondition("target.isboss", 
        function() 
            if not WR.API:UnitExists("target") then return false end
            local unit = WR.API:GetUnit("target")
            local classification = unit:GetClassification()
            return classification == "worldboss" or classification == "rareelite" or unit:GetBossID() ~= 0
        end,
        "Target is a boss")
    
    self:RegisterCondition("target.time_to_die", 
        function(seconds) 
            if not WR.API:UnitExists("target") then return false end
            local ttd = WR.Combat:GetTimeToLive("target")
            return ttd > 0 and ttd <= seconds
        end,
        "Target will die within the specified time")
    
    -- Spell conditions
    self:RegisterCondition("spell.cooldown.remains", 
        function(spellId, seconds) 
            local remains = WR.API:GetSpellCooldown(spellId)
            return remains <= seconds
        end,
        "Spell cooldown has at most the specified time remaining")
    
    self:RegisterCondition("spell.cooldown.up", 
        function(spellId) 
            return WR.API:GetSpellCooldown(spellId) == 0
        end,
        "Spell cooldown is up")
    
    self:RegisterCondition("spell.castable", 
        function(spellId, unit) 
            unit = unit or "target"
            return WR.API:IsSpellCastable(spellId, unit)
        end,
        "Spell is castable on the specified unit")
    
    self:RegisterCondition("spell.in_range", 
        function(spellId, unit) 
            unit = unit or "target"
            return WR.API:UnitExists(unit) and WR.API:IsSpellInRange(spellId, unit)
        end,
        "Spell is in range of the specified unit")
    
    -- Combat conditions
    self:RegisterCondition("combat.time", 
        function(seconds, operator) 
            operator = operator or ">"
            local combatTime = WR.Combat:GetCombatTime()
            if operator == ">" then
                return combatTime > seconds
            elseif operator == "<" then
                return combatTime < seconds
            elseif operator == ">=" then
                return combatTime >= seconds
            elseif operator == "<=" then
                return combatTime <= seconds
            elseif operator == "=" or operator == "==" then
                return combatTime == seconds
            end
            return false
        end,
        "Combat time matches the specified condition")
    
    self:RegisterCondition("enemies.count", 
        function(count, range, operator) 
            operator = operator or ">="
            range = range or 8
            local enemyCount = 0
            local units = WR.API:GetUnits()
            
            for _, unit in pairs(units) do
                if unit:Exists() and not unit:IsDead() and unit:IsEnemy() and unit:GetDistance() <= range then
                    enemyCount = enemyCount + 1
                end
            end
            
            if operator == ">" then
                return enemyCount > count
            elseif operator == "<" then
                return enemyCount < count
            elseif operator == ">=" then
                return enemyCount >= count
            elseif operator == "<=" then
                return enemyCount <= count
            elseif operator == "=" or operator == "==" then
                return enemyCount == count
            end
            return false
        end,
        "Number of enemies within range matches the specified condition")
    
    self:RegisterCondition("aoe.active", 
        function() 
            return WR.Rotation:ShouldUseAOE()
        end,
        "AOE conditions are met (config + number of targets)")
    
    self:RegisterCondition("player.casting", 
        function() 
            return UnitCastingInfo("player") ~= nil
        end,
        "Player is casting a spell")
    
    self:RegisterCondition("player.channeling", 
        function() 
            return UnitChannelInfo("player") ~= nil
        end,
        "Player is channeling a spell")
    
    -- GCD conditions
    self:RegisterCondition("gcd.remains", 
        function(seconds) 
            local remains = 0
            if WR.GCD and WR.GCD.GetGCDRemaining then
                remains = WR.GCD:GetGCDRemaining()
            else
                remains = WR.Queue:GetGCDRemaining()
            end
            return remains <= seconds
        end,
        "GCD has at most the specified time remaining")
    
    self:RegisterCondition("gcd.max", 
        function() 
            local maxGCD = 1.5
            if WR.GCD and WR.GCD.GetGCDDuration then
                maxGCD = WR.GCD:GetGCDDuration()
            end
            return maxGCD
        end,
        "Returns the maximum GCD duration")
    
    -- Talent conditions
    self:RegisterCondition("talent.active", 
        function(talentID) 
            -- This would need to be expanded based on the WoW API for talents
            -- Placeholder implementation
            return false
        end,
        "Player has the specified talent")
    
    -- Game state conditions
    self:RegisterCondition("in_dungeon", 
        function() 
            local inInstance, instanceType = IsInInstance()
            return inInstance and instanceType == "party"
        end,
        "Player is in a dungeon")
    
    self:RegisterCondition("in_raid", 
        function() 
            local inInstance, instanceType = IsInInstance()
            return inInstance and instanceType == "raid"
        end,
        "Player is in a raid")
    
    self:RegisterCondition("in_pvp", 
        function() 
            local inInstance, instanceType = IsInInstance()
            return inInstance and (instanceType == "pvp" or instanceType == "arena")
        end,
        "Player is in a PvP instance")
end

-- Initialize the condition module
Condition:Initialize()