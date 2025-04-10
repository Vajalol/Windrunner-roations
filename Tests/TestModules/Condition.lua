-- Condition module for testing - handles condition evaluation and composition
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
    -- In test environment, we don't create frames
    
    -- Register some basic test conditions
    self:RegisterPredefinedConditions()
    
    print("Condition module initialized (test environment)")
end

-- Register a condition
function Condition:RegisterCondition(name, evaluatorFunc, description)
    if type(name) ~= "string" or type(evaluatorFunc) ~= "function" then
        print("Failed to register condition - invalid parameters")
        return false
    end
    
    state.conditions[name] = {
        evaluator = evaluatorFunc,
        description = description or "No description",
    }
    
    print("Registered condition:", name)
    return true
end

-- Register a custom condition
function Condition:RegisterCustomCondition(name, evaluatorFunc, description)
    if type(name) ~= "string" or type(evaluatorFunc) ~= "function" then
        print("Failed to register custom condition - invalid parameters")
        return false
    end
    
    state.customConditions[name] = {
        evaluator = evaluatorFunc,
        description = description or "Custom condition",
    }
    
    print("Registered custom condition:", name)
    return true
end

-- Clear the condition cache
function Condition:ClearCache()
    -- Use table assignment instead of wipe
    state.conditionCaches = {}
end

-- Evaluate a condition
function Condition:Evaluate(conditionName, ...)
    state.evaluationCount = state.evaluationCount + 1
    
    -- Check if we have this condition
    local condition = state.conditions[conditionName] or state.customConditions[conditionName]
    if not condition then
        print("Unknown condition:", conditionName)
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
        print("Error evaluating condition", conditionName, result)
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

-- Get the number of condition evaluations
function Condition:GetEvaluationCount()
    return state.evaluationCount
end

-- Register basic test conditions
function Condition:RegisterPredefinedConditions()
    -- Register some basic test conditions
    self:RegisterCondition("test.always.true", 
        function() return true end,
        "Test condition that always returns true")
    
    self:RegisterCondition("test.always.false", 
        function() return false end,
        "Test condition that always returns false")
    
    self:RegisterCondition("test.compare", 
        function(a, b, operator) 
            operator = operator or "=="
            if operator == "==" then return a == b
            elseif operator == "~=" then return a ~= b
            elseif operator == ">" then return a > b
            elseif operator == ">=" then return a >= b
            elseif operator == "<" then return a < b
            elseif operator == "<=" then return a <= b
            else return false
            end
        end,
        "Test condition that compares two values")
        
    -- Some WoW-specific conditions for testing
    self:RegisterCondition("player.health.percent.below", 
        function(threshold) 
            return WR.API.UnitHealthPercent("player") < threshold 
        end,
        "Test if player health is below threshold")
        
    self:RegisterCondition("player.in.combat", 
        function() 
            return WR.API.InCombat() 
        end,
        "Test if player is in combat")
        
    self:RegisterCondition("target.distance.below", 
        function(distance) 
            return WR.API.UnitDistance("target") < distance 
        end,
        "Test if target is closer than specified distance")
end

-- Initialize the module
Condition:Initialize()

return Condition