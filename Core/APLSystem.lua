------------------------------------------
-- WindrunnerRotations - Action Priority List System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local APLSystem = {}
WR.APLSystem = APLSystem

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- APL storage and management
local aplLists = {}
local userDefinedAPLs = {}
local defaultAPLs = {}
local currentAPL = nil
local cachedAPLResults = {}
local cachedVariables = {}
local lastActionTime = 0
local lastActionName = ""
local actionHistory = {}
local actionCounts = {}
local MAX_HISTORY = 20
local variableCache = {}
local conditionCache = {}
local conditionEvalTime = {}
local actionTimes = {}
local enabledAPLs = {}
local CACHE_DURATION = 0.1 -- seconds

-- Initialize the APL System
function APLSystem:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register slash command
    SLASH_WRAPL1 = "/wrapl"
    SlashCmdList["WRAPL"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    -- Load saved APLs
    self:LoadSavedAPLs()
    
    -- Register for module loading
    ModuleManager:RegisterCallback("OnModuleLoaded", function(moduleTable)
        self:RegisterDefaultAPLsForModule(moduleTable)
    end)
    
    -- Register for spec changes
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:UpdateCurrentAPL()
        end
    end)
    
    API.PrintDebug("APL System initialized")
    return true
end

-- Register settings for the APL System
function APLSystem:RegisterSettings()
    ConfigRegistry:RegisterSettings("APLSystem", {
        generalSettings = {
            enableAPLSystem = {
                displayName = "Enable APL System",
                description = "Enable the Action Priority List system",
                type = "toggle",
                default = true
            },
            useCustomAPLs = {
                displayName = "Use Custom APLs",
                description = "Use custom user-defined APLs when available",
                type = "toggle",
                default = true
            },
            fallbackToDefault = {
                displayName = "Fallback to Default APLs",
                description = "Fall back to default APLs if custom APLs fail",
                type = "toggle",
                default = true
            },
            reportAPLActions = {
                displayName = "Report APL Actions",
                description = "Report APL actions to chat",
                type = "toggle",
                default = false
            },
            cacheSettings = {
                displayName = "Caching Settings",
                description = "Settings for APL calculation caching",
                type = "group",
                settings = {
                    enableCaching = {
                        displayName = "Enable Caching",
                        description = "Enable caching of APL calculations",
                        type = "toggle",
                        default = true
                    },
                    cacheDuration = {
                        displayName = "Cache Duration",
                        description = "Duration (in seconds) to cache APL calculations",
                        type = "slider",
                        min = 0.05,
                        max = 1.0,
                        step = 0.05,
                        default = 0.1
                    }
                }
            }
        },
        editorSettings = {
            showLineNumbers = {
                displayName = "Show Line Numbers",
                description = "Show line numbers in the APL editor",
                type = "toggle",
                default = true
            },
            syntaxHighlighting = {
                displayName = "Syntax Highlighting",
                description = "Enable syntax highlighting in the APL editor",
                type = "toggle",
                default = true
            },
            autoComplete = {
                displayName = "Auto-Complete",
                description = "Enable auto-complete in the APL editor",
                type = "toggle",
                default = true
            },
            fontSize = {
                displayName = "Font Size",
                description = "Font size for the APL editor",
                type = "slider",
                min = 8,
                max = 18,
                step = 1,
                default = 12
            }
        },
        debugSettings = {
            enableDebugMode = {
                displayName = "Enable Debug Mode",
                description = "Enable debug mode for APL execution",
                type = "toggle",
                default = false
            },
            logUnmetConditions = {
                displayName = "Log Unmet Conditions",
                description = "Log conditions that aren't met during APL execution",
                type = "toggle",
                default = false
            },
            logVariableValues = {
                displayName = "Log Variable Values",
                description = "Log variable values during APL execution",
                type = "toggle",
                default = false
            },
            logExecutionTime = {
                displayName = "Log Execution Time",
                description = "Log execution time for APL calculations",
                type = "toggle",
                default = false
            }
        }
    })
}

-- Load saved APLs from user configuration
function APLSystem:LoadSavedAPLs()
    -- In a real addon, this would load from SavedVariables
    -- For our implementation, initialize with empty tables
    
    userDefinedAPLs = {}
    
    -- Load enabled APLs
    enabledAPLs = {}
    
    -- Update current APL
    self:UpdateCurrentAPL()
}

-- Save APLs to user configuration
function APLSystem:SaveAPLs()
    -- In a real addon, this would save to SavedVariables
    -- For our implementation, just log it
    
    API.PrintDebug("APLs saved")
}

-- Update the current APL based on class/spec
function APLSystem:UpdateCurrentAPL()
    local specID = API.GetActiveSpecID()
    if not specID then
        currentAPL = nil
        return
    end
    
    -- Check if there's a user-defined APL for this spec
    local settings = ConfigRegistry:GetSettings("APLSystem")
    if settings.generalSettings.useCustomAPLs and userDefinedAPLs[specID] and enabledAPLs[specID] then
        currentAPL = userDefinedAPLs[specID]
        API.PrintDebug("Using custom APL for spec " .. specID)
    -- Fall back to default
    elseif settings.generalSettings.fallbackToDefault and defaultAPLs[specID] then
        currentAPL = defaultAPLs[specID]
        API.PrintDebug("Using default APL for spec " .. specID)
    else
        currentAPL = nil
        API.PrintDebug("No APL available for spec " .. specID)
    end
    
    -- Clear caches on APL change
    self:ClearCaches()
}

-- Clear calculation caches
function APLSystem:ClearCaches()
    cachedAPLResults = {}
    cachedVariables = {}
    variableCache = {}
    conditionCache = {}
    actionHistory = {}
    actionCounts = {}
}

-- Register default APLs for a module
function APLSystem:RegisterDefaultAPLsForModule(moduleTable)
    if not moduleTable or not moduleTable.specID then return end
    
    local specID = moduleTable.specID
    
    -- Create a default APL for this spec
    local defaultAPL = self:CreateDefaultAPL(moduleTable)
    
    if defaultAPL then
        defaultAPLs[specID] = defaultAPL
        API.PrintDebug("Registered default APL for " .. moduleTable.name)
        
        -- Update current APL if this is the active spec
        if API.GetActiveSpecID() == specID then
            self:UpdateCurrentAPL()
        end
    end
}

-- Create a default APL based on a module's rotation
function APLSystem:CreateDefaultAPL(moduleTable)
    if not moduleTable or not moduleTable.RunRotation then return nil end
    
    -- Create a simple APL that wraps the module's rotation logic
    local defaultAPL = {
        name = moduleTable.name .. " Default",
        specID = moduleTable.specID,
        author = "WindrunnerRotations",
        description = "Default APL for " .. moduleTable.name,
        version = "1.0",
        lists = {
            default = {
                { action = "call_native_rotation", conditions = {} }
            }
        },
        variables = {},
        functions = {
            call_native_rotation = function(state)
                return moduleTable:RunRotation()
            end
        }
    }
    
    return defaultAPL
}

-- Register a custom APL
function APLSystem:RegisterCustomAPL(apl)
    if not apl or not apl.specID or not apl.name or not apl.lists then
        return false, "Invalid APL structure"
    end
    
    -- Compile and validate the APL
    local success, result = self:CompileAPL(apl)
    if not success then
        return false, "Failed to compile APL: " .. result
    end
    
    -- Store the APL
    userDefinedAPLs[apl.specID] = result
    
    -- Enable by default
    enabledAPLs[apl.specID] = true
    
    -- Save APLs
    self:SaveAPLs()
    
    -- Update current APL if this is for the active spec
    if API.GetActiveSpecID() == apl.specID then
        self:UpdateCurrentAPL()
    end
    
    return true
}

-- Run the current APL
function APLSystem:RunAPL()
    -- Check if APL system is enabled
    local settings = ConfigRegistry:GetSettings("APLSystem")
    if not settings.generalSettings.enableAPLSystem then
        return false
    end
    
    -- Check if we have a current APL
    if not currentAPL then
        return false
    end
    
    -- Check for cached result
    local now = GetTime()
    local cacheEnabled = settings.generalSettings.cacheSettings.enableCaching
    local cacheDuration = settings.generalSettings.cacheSettings.cacheDuration
    
    if cacheEnabled and cachedAPLResults.time and (now - cachedAPLResults.time) < cacheDuration then
        return cachedAPLResults.result, cachedAPLResults.action
    end
    
    -- Create state for APL execution
    local state = self:CreateAPLState()
    
    -- Execute the APL
    local startTime = debugprofilestop()
    local success, action = self:ExecuteAPL(currentAPL, state)
    local endTime = debugprofilestop()
    
    if settings.debugSettings.logExecutionTime then
        API.PrintDebug("APL execution time: " .. (endTime - startTime) .. "ms")
    end
    
    -- Cache the result
    if cacheEnabled then
        cachedAPLResults = {
            time = now,
            result = success,
            action = action
        }
    end
    
    -- Track action history
    if success and action then
        self:TrackAction(action)
    end
    
    -- Report action
    if success and action and settings.generalSettings.reportAPLActions then
        API.Print("APL action: " .. action)
    end
    
    return success, action
}

-- Execute an APL
function APLSystem:ExecuteAPL(apl, state)
    if not apl or not apl.lists or not apl.lists.default then
        return false
    end
    
    -- First handle variable definitions
    self:EvaluateVariables(apl, state)
    
    -- Execute the default list
    return self:ExecuteAPLList(apl, "default", state)
}

-- Execute an APL list
function APLSystem:ExecuteAPLList(apl, listName, state)
    if not apl or not apl.lists or not apl.lists[listName] then
        return false
    end
    
    local list = apl.lists[listName]
    
    -- Process each entry in the list
    for i, entry in ipairs(list) do
        -- Check if this is a sub-list call
        if entry.list then
            local success, action = self:ExecuteAPLList(apl, entry.list, state)
            if success then
                return true, action
            end
        -- Otherwise it's an action
        elseif entry.action then
            -- Check conditions
            local conditionsMet = self:EvaluateConditions(entry.conditions, state)
            
            if conditionsMet then
                -- Execute the action
                local success, action = self:ExecuteAction(apl, entry.action, state)
                if success then
                    return true, action
                end
            end
        end
    end
    
    return false
}

-- Evaluate variables
function APLSystem:EvaluateVariables(apl, state)
    if not apl.variables then return end
    
    local settings = ConfigRegistry:GetSettings("APLSystem")
    local debugEnabled = settings.debugSettings.enableDebugMode
    local logVariables = settings.debugSettings.logVariableValues
    
    for name, definition in pairs(apl.variables) do
        if type(definition) == "function" then
            -- Execute the function
            local success, value = pcall(definition, state)
            if success then
                state.variables[name] = value
                variableCache[name] = {
                    time = GetTime(),
                    value = value
                }
                
                if debugEnabled and logVariables then
                    API.PrintDebug("Variable " .. name .. " = " .. tostring(value))
                end
            end
        elseif type(definition) == "string" then
            -- Parse and evaluate the expression
            local success, value = self:EvaluateExpression(definition, state)
            if success then
                state.variables[name] = value
                variableCache[name] = {
                    time = GetTime(),
                    value = value
                }
                
                if debugEnabled and logVariables then
                    API.PrintDebug("Variable " .. name .. " = " .. tostring(value))
                end
            end
        else
            -- Direct value
            state.variables[name] = definition
            variableCache[name] = {
                time = GetTime(),
                value = definition
            }
            
            if debugEnabled and logVariables then
                API.PrintDebug("Variable " .. name .. " = " .. tostring(definition))
            end
        end
    end
end

-- Evaluate conditions
function APLSystem:EvaluateConditions(conditions, state)
    if not conditions or #conditions == 0 then
        return true
    end
    
    local settings = ConfigRegistry:GetSettings("APLSystem")
    local debugEnabled = settings.debugSettings.enableDebugMode
    local logUnmetConditions = settings.debugSettings.logUnmetConditions
    
    -- Process each condition
    for i, condition in ipairs(conditions) do
        -- Check condition cache
        local conditionKey = tostring(condition)
        if conditionCache[conditionKey] and GetTime() - conditionCache[conditionKey].time < CACHE_DURATION then
            if not conditionCache[conditionKey].result and debugEnabled and logUnmetConditions then
                API.PrintDebug("Condition not met (cached): " .. conditionKey)
            end
            return conditionCache[conditionKey].result
        end
        
        local startTime = debugprofilestop()
        
        -- Handle different condition types
        local result = false
        
        if type(condition) == "function" then
            -- Execute function condition
            local success, value = pcall(condition, state)
            result = success and value
        elseif type(condition) == "string" then
            -- Parse and evaluate expression
            local success, value = self:EvaluateExpression(condition, state)
            result = success and value
        elseif type(condition) == "table" then
            -- Handle complex condition
            result = self:EvaluateComplexCondition(condition, state)
        else
            -- Direct boolean value
            result = condition and true or false
        end
        
        local endTime = debugprofilestop()
        
        -- Update condition timing stats
        conditionEvalTime[conditionKey] = (conditionEvalTime[conditionKey] or 0) + (endTime - startTime)
        
        -- Cache the result
        conditionCache[conditionKey] = {
            time = GetTime(),
            result = result
        }
        
        -- If any condition is false, the whole set is false
        if not result then
            if debugEnabled and logUnmetConditions then
                API.PrintDebug("Condition not met: " .. conditionKey)
            end
            return false
        end
    end
    
    -- All conditions were true
    return true
end

-- Evaluate a complex condition
function APLSystem:EvaluateComplexCondition(condition, state)
    if not condition or not condition.type then
        return false
    end
    
    -- Handle different condition types
    if condition.type == "and" then
        -- All subconditions must be true
        return self:EvaluateConditions(condition.conditions, state)
    elseif condition.type == "or" then
        -- Any subcondition may be true
        for i, subcondition in ipairs(condition.conditions) do
            if self:EvaluateConditions({subcondition}, state) then
                return true
            end
        end
        return false
    elseif condition.type == "not" then
        -- Invert the result
        return not self:EvaluateConditions({condition.condition}, state)
    elseif condition.type == "spell" then
        -- Check spell-related conditions
        return self:EvaluateSpellCondition(condition, state)
    elseif condition.type == "resource" then
        -- Check resource-related conditions
        return self:EvaluateResourceCondition(condition, state)
    elseif condition.type == "aura" then
        -- Check aura-related conditions
        return self:EvaluateAuraCondition(condition, state)
    elseif condition.type == "state" then
        -- Check state-related conditions
        return self:EvaluateStateCondition(condition, state)
    elseif condition.type == "target" then
        -- Check target-related conditions
        return self:EvaluateTargetCondition(condition, state)
    elseif condition.type == "combat" then
        -- Check combat-related conditions
        return self:EvaluateCombatCondition(condition, state)
    elseif condition.type == "compare" then
        -- Compare values
        return self:EvaluateCompareCondition(condition, state)
    elseif condition.type == "time" then
        -- Check time-related conditions
        return self:EvaluateTimeCondition(condition, state)
    elseif condition.type == "variable" then
        -- Check variable-related conditions
        return self:EvaluateVariableCondition(condition, state)
    end
    
    return false
end

-- Evaluate a spell condition
function APLSystem:EvaluateSpellCondition(condition, state)
    if not condition.spell then
        return false
    end
    
    local spellID = condition.spell
    
    -- Handle different spell condition types
    if condition.check == "can_cast" then
        return API.CanCast(spellID)
    elseif condition.check == "cooldown" then
        local cooldown = API.GetSpellCooldown(spellID)
        if condition.operator == "=" or condition.operator == "==" then
            return cooldown == condition.value
        elseif condition.operator == "<" then
            return cooldown < condition.value
        elseif condition.operator == ">" then
            return cooldown > condition.value
        elseif condition.operator == "<=" then
            return cooldown <= condition.value
        elseif condition.operator == ">=" then
            return cooldown >= condition.value
        elseif condition.operator == "ready" then
            return cooldown <= 0
        end
    elseif condition.check == "charges" then
        local charges = API.GetSpellCharges(spellID)
        if condition.operator == "=" or condition.operator == "==" then
            return charges == condition.value
        elseif condition.operator == "<" then
            return charges < condition.value
        elseif condition.operator == ">" then
            return charges > condition.value
        elseif condition.operator == "<=" then
            return charges <= condition.value
        elseif condition.operator == ">=" then
            return charges >= condition.value
        end
    elseif condition.check == "known" then
        return API.IsSpellKnown(spellID)
    end
    
    return false
end

-- Evaluate a resource condition
function APLSystem:EvaluateResourceCondition(condition, state)
    if not condition.resource then
        return false
    end
    
    local resource = condition.resource
    local value = 0
    
    -- Get current resource value
    if resource == "mana" then
        value = API.GetPlayerManaPercentage()
    elseif resource == "rage" or resource == "energy" or resource == "focus" then
        value = API.GetPowerResource(resource)
    elseif resource == "combo_points" then
        value = API.GetComboPoints("player", "target")
    elseif resource == "runes" then
        value = API.GetRuneCount()
    elseif resource == "arcane_charges" then
        value = API.GetArcaneCharges()
    elseif resource == "holy_power" then
        value = API.GetPowerResource("holypower")
    elseif resource == "soul_shards" then
        value = API.GetPowerResource("soulshards")
    elseif resource == "chi" then
        value = API.GetPowerResource("chi")
    else
        -- For other resources, try generic API
        value = API.GetPowerResource(resource) or 0
    end
    
    -- Perform comparison
    if condition.operator == "=" or condition.operator == "==" then
        return value == condition.value
    elseif condition.operator == "<" then
        return value < condition.value
    elseif condition.operator == ">" then
        return value > condition.value
    elseif condition.operator == "<=" then
        return value <= condition.value
    elseif condition.operator == ">=" then
        return value >= condition.value
    elseif condition.operator == "deficit" then
        local max = API.GetMaxPowerResource(resource) or 100
        return (max - value) >= condition.value
    end
    
    return false
end

-- Evaluate an aura condition
function APLSystem:EvaluateAuraCondition(condition, state)
    if not condition.aura then
        return false
    end
    
    local unit = condition.unit or "player"
    local auraID = condition.aura
    
    -- Handle different aura condition types
    if condition.check == "exists" or condition.check == "active" then
        return API.HasBuff(unit, auraID)
    elseif condition.check == "missing" then
        return not API.HasBuff(unit, auraID)
    elseif condition.check == "duration" then
        local duration = select(5, API.GetBuffInfo(unit, auraID))
        if not duration then return false end
        
        if condition.operator == "=" or condition.operator == "==" then
            return duration == condition.value
        elseif condition.operator == "<" then
            return duration < condition.value
        elseif condition.operator == ">" then
            return duration > condition.value
        elseif condition.operator == "<=" then
            return duration <= condition.value
        elseif condition.operator == ">=" then
            return duration >= condition.value
        end
    elseif condition.check == "stacks" then
        local stacks = select(4, API.GetBuffInfo(unit, auraID))
        if not stacks then return false end
        
        if condition.operator == "=" or condition.operator == "==" then
            return stacks == condition.value
        elseif condition.operator == "<" then
            return stacks < condition.value
        elseif condition.operator == ">" then
            return stacks > condition.value
        elseif condition.operator == "<=" then
            return stacks <= condition.value
        elseif condition.operator == ">=" then
            return stacks >= condition.value
        end
    end
    
    return false
end

-- Evaluate a state condition
function APLSystem:EvaluateStateCondition(condition, state)
    if not condition.check then
        return false
    end
    
    -- Handle different state condition types
    if condition.check == "moving" then
        return API.IsPlayerMoving()
    elseif condition.check == "falling" then
        return API.IsFalling()
    elseif condition.check == "casting" then
        return API.IsPlayerCasting()
    elseif condition.check == "channeling" then
        return API.IsPlayerChanneling()
    elseif condition.check == "dead" then
        return API.IsPlayerDead()
    elseif condition.check == "mounted" then
        return API.IsPlayerMounted()
    elseif condition.check == "in_vehicle" then
        return API.IsPlayerInVehicle()
    elseif condition.check == "talent" then
        return API.HasTalent(condition.talent)
    elseif condition.check == "spec" then
        return API.GetActiveSpecID() == condition.spec
    end
    
    return false
end

-- Evaluate a target condition
function APLSystem:EvaluateTargetCondition(condition, state)
    if not condition.check then
        return false
    end
    
    local unit = condition.unit or "target"
    
    -- Handle different target condition types
    if condition.check == "exists" then
        return API.UnitExists(unit)
    elseif condition.check == "enemy" then
        return API.IsUnitEnemy(unit)
    elseif condition.check == "friend" then
        return API.IsUnitFriendly(unit)
    elseif condition.check == "health" then
        local health = API.GetUnitHealthPercent(unit)
        if not health then return false end
        
        if condition.operator == "=" or condition.operator == "==" then
            return health == condition.value
        elseif condition.operator == "<" then
            return health < condition.value
        elseif condition.operator == ">" then
            return health > condition.value
        elseif condition.operator == "<=" then
            return health <= condition.value
        elseif condition.operator == ">=" then
            return health >= condition.value
        end
    elseif condition.check == "in_range" then
        return API.IsUnitInRange(unit, condition.range or 30)
    elseif condition.check == "distance" then
        local distance = API.GetUnitDistance(unit)
        if not distance then return false end
        
        if condition.operator == "=" or condition.operator == "==" then
            return distance == condition.value
        elseif condition.operator == "<" then
            return distance < condition.value
        elseif condition.operator == ">" then
            return distance > condition.value
        elseif condition.operator == "<=" then
            return distance <= condition.value
        elseif condition.operator == ">=" then
            return distance >= condition.value
        end
    elseif condition.check == "casting" then
        return API.IsUnitCasting(unit)
    elseif condition.check == "level" then
        local level = API.GetUnitLevel(unit)
        if not level then return false end
        
        if condition.operator == "=" or condition.operator == "==" then
            return level == condition.value
        elseif condition.operator == "<" then
            return level < condition.value
        elseif condition.operator == ">" then
            return level > condition.value
        elseif condition.operator == "<=" then
            return level <= condition.value
        elseif condition.operator == ">=" then
            return level >= condition.value
        end
    end
    
    return false
end

-- Evaluate a combat condition
function APLSystem:EvaluateCombatCondition(condition, state)
    if not condition.check then
        return false
    end
    
    -- Handle different combat condition types
    if condition.check == "in_combat" then
        return API.IsPlayerInCombat()
    elseif condition.check == "time" then
        local combatTime = API.GetCombatTime()
        if not combatTime then return false end
        
        if condition.operator == "=" or condition.operator == "==" then
            return combatTime == condition.value
        elseif condition.operator == "<" then
            return combatTime < condition.value
        elseif condition.operator == ">" then
            return combatTime > condition.value
        elseif condition.operator == "<=" then
            return combatTime <= condition.value
        elseif condition.operator == ">=" then
            return combatTime >= condition.value
        end
    elseif condition.check == "enemies" then
        local enemies = API.GetEnemyCount() or 0
        
        if condition.operator == "=" or condition.operator == "==" then
            return enemies == condition.value
        elseif condition.operator == "<" then
            return enemies < condition.value
        elseif condition.operator == ">" then
            return enemies > condition.value
        elseif condition.operator == "<=" then
            return enemies <= condition.value
        elseif condition.operator == ">=" then
            return enemies >= condition.value
        end
    end
    
    return false
end

-- Evaluate a compare condition
function APLSystem:EvaluateCompareCondition(condition, state)
    if not condition.value1 or not condition.value2 or not condition.operator then
        return false
    end
    
    -- Evaluate values
    local val1, val2
    
    if type(condition.value1) == "string" and condition.value1:sub(1, 1) == "$" then
        -- Variable reference
        local varName = condition.value1:sub(2)
        val1 = state.variables[varName]
    else
        val1 = condition.value1
    end
    
    if type(condition.value2) == "string" and condition.value2:sub(1, 1) == "$" then
        -- Variable reference
        local varName = condition.value2:sub(2)
        val2 = state.variables[varName]
    else
        val2 = condition.value2
    end
    
    -- Perform comparison
    if condition.operator == "=" or condition.operator == "==" then
        return val1 == val2
    elseif condition.operator == "!=" or condition.operator == "<>" then
        return val1 ~= val2
    elseif condition.operator == "<" then
        return val1 < val2
    elseif condition.operator == ">" then
        return val1 > val2
    elseif condition.operator == "<=" then
        return val1 <= val2
    elseif condition.operator == ">=" then
        return val1 >= val2
    end
    
    return false
end

-- Evaluate a time condition
function APLSystem:EvaluateTimeCondition(condition, state)
    if not condition.check then
        return false
    end
    
    -- Handle different time condition types
    if condition.check == "since_last" then
        local actionName = condition.action
        if not lastActionTime or not lastActionName or lastActionName ~= actionName then
            return false
        end
        
        local timeSince = GetTime() - lastActionTime
        
        if condition.operator == "=" or condition.operator == "==" then
            return timeSince == condition.value
        elseif condition.operator == "<" then
            return timeSince < condition.value
        elseif condition.operator == ">" then
            return timeSince > condition.value
        elseif condition.operator == "<=" then
            return timeSince <= condition.value
        elseif condition.operator == ">=" then
            return timeSince >= condition.value
        end
    end
    
    return false
end

-- Evaluate a variable condition
function APLSystem:EvaluateVariableCondition(condition, state)
    if not condition.variable then
        return false
    end
    
    local varName = condition.variable
    local value = state.variables[varName]
    
    if value == nil then
        return false
    end
    
    -- Handle boolean variables
    if condition.check == "exists" then
        return value ~= nil
    elseif condition.check == "true" then
        return value == true
    elseif condition.check == "false" then
        return value == false
    end
    
    -- Handle numeric comparisons
    if condition.operator == "=" or condition.operator == "==" then
        return value == condition.value
    elseif condition.operator == "!=" or condition.operator == "<>" then
        return value ~= condition.value
    elseif condition.operator == "<" then
        return value < condition.value
    elseif condition.operator == ">" then
        return value > condition.value
    elseif condition.operator == "<=" then
        return value <= condition.value
    elseif condition.operator == ">=" then
        return value >= condition.value
    end
    
    return false
end

-- Evaluate an expression
function APLSystem:EvaluateExpression(expression, state)
    if not expression then
        return false, nil
    end
    
    -- Handle simple variable references
    if expression:sub(1, 1) == "$" then
        local varName = expression:sub(2)
        return true, state.variables[varName]
    end
    
    -- In a real implementation, this would include a proper expression parser
    -- For our implementation, we'll handle a few simple cases
    
    -- Check for comparisons
    local val1, op, val2 = expression:match("(.+)%s*([=<>!]+)%s*(.+)")
    if val1 and op and val2 then
        -- Evaluate values
        local success1, result1 = self:EvaluateExpression(val1, state)
        local success2, result2 = self:EvaluateExpression(val2, state)
        
        if not success1 or not success2 then
            return false, nil
        end
        
        -- Perform comparison
        if op == "=" or op == "==" then
            return true, result1 == result2
        elseif op == "!=" or op == "<>" then
            return true, result1 ~= result2
        elseif op == "<" then
            return true, result1 < result2
        elseif op == ">" then
            return true, result1 > result2
        elseif op == "<=" then
            return true, result1 <= result2
        elseif op == ">=" then
            return true, result1 >= result2
        end
    end
    
    -- Check for function calls
    local funcName, args = expression:match("([%w_]+)%((.*)%)")
    if funcName and args then
        -- Split arguments
        local argValues = {}
        for arg in args:gmatch("[^,]+") do
            arg = arg:match("^%s*(.-)%s*$") -- Trim whitespace
            local success, result = self:EvaluateExpression(arg, state)
            if not success then
                return false, nil
            end
            table.insert(argValues, result)
        end
        
        -- Execute function
        if type(state.functions[funcName]) == "function" then
            local success, result = pcall(state.functions[funcName], unpack(argValues))
            return success, result
        end
    end
    
    -- Handle direct values
    local number = tonumber(expression)
    if number then
        return true, number
    end
    
    if expression == "true" then
        return true, true
    elseif expression == "false" then
        return true, false
    end
    
    -- If all else fails, return the expression as a string
    return true, expression
end

-- Execute an action
function APLSystem:ExecuteAction(apl, action, state)
    if not action then
        return false
    end
    
    -- Handle different action types
    if type(action) == "function" then
        -- Execute function action
        local success, result = pcall(action, state)
        return success, result and result or action
    elseif type(action) == "string" then
        -- Handle action string
        if action:sub(1, 5) == "cast_" then
            -- Cast spell actions
            local spellID = tonumber(action:sub(6))
            if not spellID then
                -- Try to parse spell name
                spellID = API.GetSpellIDFromName(action:sub(6))
            end
            
            if spellID and API.CanCast(spellID) then
                if action:find("_on_") then
                    -- Cast on specific target
                    local target = action:match("_on_(.+)$")
                    API.CastSpellOnUnit(spellID, target)
                else
                    -- Cast on default target
                    API.CastSpell(spellID)
                end
                return true, action
            end
        elseif action:sub(1, 5) == "call_" then
            -- Call function
            local funcName = action:sub(6)
            if apl.functions and apl.functions[funcName] then
                local success, result = pcall(apl.functions[funcName], state)
                return success, result and action or false
            end
        elseif action:sub(1, 6) == "return" then
            -- Return value
            local value = action:sub(8)
            return true, value
        elseif action == "call_native_rotation" then
            -- Use the module's native rotation
            return true, "native_rotation"
        end
    end
    
    return false
}

-- Create the APL execution state
function APLSystem:CreateAPLState()
    local state = {
        variables = {},
        functions = {
            -- Basic math functions
            min = math.min,
            max = math.max,
            floor = math.floor,
            ceil = math.ceil,
            round = function(x) return math.floor(x + 0.5) end,
            
            -- WoW API functions
            spell_cooldown = function(spellID)
                return API.GetSpellCooldown(spellID)
            end,
            has_buff = function(unit, buffID)
                return API.HasBuff(unit, buffID) and 1 or 0
            end,
            buff_duration = function(unit, buffID)
                return select(5, API.GetBuffInfo(unit, buffID)) or 0
            end,
            buff_stacks = function(unit, buffID)
                return select(4, API.GetBuffInfo(unit, buffID)) or 0
            end,
            health_percent = function(unit)
                return API.GetUnitHealthPercent(unit) or 0
            end,
            mana_percent = function()
                return API.GetPlayerManaPercentage() or 0
            end,
            power_resource = function(resource)
                return API.GetPowerResource(resource) or 0
            end,
            enemy_count = function()
                return API.GetEnemyCount() or 0
            end,
            combat_time = function()
                return API.GetCombatTime() or 0
            end,
            in_range = function(unit, range)
                return API.IsUnitInRange(unit, range) and 1 or 0
            end,
            is_moving = function()
                return API.IsPlayerMoving() and 1 or 0
            end,
            spell_usable = function(spellID)
                return API.CanCast(spellID) and 1 or 0
            end
        }
    }
    
    -- Apply cached variable values
    for varName, cache in pairs(variableCache) do
        if GetTime() - cache.time < CACHE_DURATION then
            state.variables[varName] = cache.value
        end
    end
    
    return state
}

-- Compile an APL definition
function APLSystem:CompileAPL(apl)
    if not apl or not apl.lists or not apl.lists.default then
        return false, "Missing required APL structure"
    end
    
    -- Create a compiled version of the APL
    local compiled = {
        name = apl.name,
        specID = apl.specID,
        author = apl.author,
        description = apl.description,
        version = apl.version,
        lists = {},
        variables = apl.variables or {},
        functions = apl.functions or {}
    }
    
    -- Compile each list
    for listName, list in pairs(apl.lists) do
        compiled.lists[listName] = self:CompileAPLList(list)
    end
    
    return true, compiled
end

-- Compile an APL list
function APLSystem:CompileAPLList(list)
    if not list or type(list) ~= "table" then
        return {}
    end
    
    local compiled = {}
    
    for i, entry in ipairs(list) do
        local compiledEntry = {}
        
        -- Copy action or list reference
        if entry.action then
            compiledEntry.action = entry.action
        elseif entry.list then
            compiledEntry.list = entry.list
        end
        
        -- Compile conditions
        if entry.conditions then
            compiledEntry.conditions = {}
            for j, condition in ipairs(entry.conditions) do
                -- Add directly for now
                table.insert(compiledEntry.conditions, condition)
            end
        else
            compiledEntry.conditions = {}
        end
        
        table.insert(compiled, compiledEntry)
    end
    
    return compiled
end

-- Track executed actions
function APLSystem:TrackAction(action)
    -- Record the action
    lastActionTime = GetTime()
    lastActionName = action
    
    -- Add to history
    table.insert(actionHistory, {
        time = lastActionTime,
        action = action
    })
    
    -- Trim history if needed
    if #actionHistory > MAX_HISTORY then
        table.remove(actionHistory, 1)
    end
    
    -- Count actions
    actionCounts[action] = (actionCounts[action] or 0) + 1
    
    -- Track execution time
    if not actionTimes[action] then
        actionTimes[action] = {
            count = 1,
            totalTime = 0,
            lastTime = lastActionTime
        }
    else
        actionTimes[action].count = actionTimes[action].count + 1
        if actionTimes[action].lastTime then
            local timeSince = lastActionTime - actionTimes[action].lastTime
            actionTimes[action].totalTime = actionTimes[action].totalTime + timeSince
        end
        actionTimes[action].lastTime = lastActionTime
    end
}

-- Handle slash command
function APLSystem:HandleSlashCommand(msg)
    if not msg or msg == "" then
        -- Show help
        API.Print("WindrunnerRotations APL System Commands:")
        API.Print("/wrapl status - Show current APL status")
        API.Print("/wrapl list - List available APLs")
        API.Print("/wrapl enable [id] - Enable an APL")
        API.Print("/wrapl disable [id] - Disable an APL")
        API.Print("/wrapl import [string] - Import an APL")
        API.Print("/wrapl export - Export the current APL")
        API.Print("/wrapl editor - Open the APL editor")
        API.Print("/wrapl debug - Toggle debug mode")
        return
    end
    
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    if command == "status" then
        -- Show current APL status
        local specID = API.GetActiveSpecID()
        local settings = ConfigRegistry:GetSettings("APLSystem")
        
        API.Print("APL System Status:")
        API.Print("Enabled: " .. (settings.generalSettings.enableAPLSystem and "Yes" or "No"))
        API.Print("Current Spec: " .. API.GetSpecName(specID))
        
        if currentAPL then
            API.Print("Current APL: " .. currentAPL.name)
            API.Print("Author: " .. (currentAPL.author or "Unknown"))
            API.Print("Version: " .. (currentAPL.version or "Unknown"))
            if currentAPL.description then
                API.Print("Description: " .. currentAPL.description)
            end
        else
            API.Print("No current APL")
        end
        
        API.Print("Custom APLs: " .. (next(userDefinedAPLs) and "Yes" or "No"))
        API.Print("Default APLs: " .. (next(defaultAPLs) and "Yes" or "No"))
    elseif command == "list" then
        -- List available APLs
        local specID = API.GetActiveSpecID()
        
        API.Print("Available APLs:")
        
        if userDefinedAPLs[specID] then
            API.Print("Custom APLs:")
            for id, apl in pairs(userDefinedAPLs) do
                if apl.specID == specID then
                    API.Print("  - " .. apl.name .. " (" .. id .. ")" .. (enabledAPLs[id] and " [Enabled]" or ""))
                end
            end
        end
        
        if defaultAPLs[specID] then
            API.Print("Default APLs:")
            for id, apl in pairs(defaultAPLs) do
                if apl.specID == specID then
                    API.Print("  - " .. apl.name .. " (" .. id .. ")")
                end
            end
        end
    elseif command == "enable" then
        -- Enable an APL
        local id = args[2]
        if not id then
            API.Print("Please provide an APL ID")
            return
        end
        
        local aplToEnable = userDefinedAPLs[id]
        if not aplToEnable then
            API.Print("APL not found: " .. id)
            return
        end
        
        enabledAPLs[id] = true
        self:SaveAPLs()
        
        -- Update current APL if this is for the active spec
        if API.GetActiveSpecID() == aplToEnable.specID then
            self:UpdateCurrentAPL()
        end
        
        API.Print("APL enabled: " .. aplToEnable.name)
    elseif command == "disable" then
        -- Disable an APL
        local id = args[2]
        if not id then
            API.Print("Please provide an APL ID")
            return
        end
        
        local aplToDisable = userDefinedAPLs[id]
        if not aplToDisable then
            API.Print("APL not found: " .. id)
            return
        end
        
        enabledAPLs[id] = false
        self:SaveAPLs()
        
        -- Update current APL if this is for the active spec
        if API.GetActiveSpecID() == aplToDisable.specID then
            self:UpdateCurrentAPL()
        end
        
        API.Print("APL disabled: " .. aplToDisable.name)
    elseif command == "import" then
        -- Import an APL
        local importString = args[2]
        if not importString then
            API.Print("Please provide an import string")
            return
        end
        
        -- In a real addon, this would parse the import string
        -- For our implementation, we'll just create a placeholder APL
        local apl = {
            name = "Imported APL",
            specID = API.GetActiveSpecID(),
            author = "Import",
            description = "Imported APL",
            version = "1.0",
            lists = {
                default = {
                    { action = "call_native_rotation", conditions = {} }
                }
            }
        }
        
        local success, id = self:RegisterCustomAPL(apl)
        if success then
            API.Print("APL imported: " .. apl.name .. " (ID: " .. id .. ")")
        else
            API.Print("Failed to import APL: " .. (id or "Unknown error"))
        end
    elseif command == "export" then
        -- Export the current APL
        if not currentAPL then
            API.Print("No current APL to export")
            return
        end
        
        -- In a real addon, this would generate an export string
        -- For our implementation, we'll just show a placeholder
        API.Print("APL export string:")
        API.Print("WRAPL:1:" .. currentAPL.name .. ":" .. currentAPL.specID .. ":<data>")
    elseif command == "editor" then
        -- Open the APL editor
        API.Print("APL editor not available in this version")
    elseif command == "debug" then
        -- Toggle debug mode
        local settings = ConfigRegistry:GetSettings("APLSystem")
        local newValue = not settings.debugSettings.enableDebugMode
        
        ConfigRegistry:SetSettingValue("APLSystem", "debugSettings.enableDebugMode", newValue)
        
        API.Print("APL debug mode " .. (newValue and "enabled" or "disabled"))
    else
        API.Print("Unknown command. Type /wrapl for help.")
    end
end

-- Return the module for loading
return APLSystem