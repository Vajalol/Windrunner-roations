-- PriorityQueue.lua
-- Handles dynamic ability prioritization
local addonName, WR = ...
local PriorityQueue = {}
WR.PriorityQueue = PriorityQueue

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local enablePriorityQueue = true
local adaptivePriorities = true
local overrideBaseRotation = true
local priorityQueueLastUpdated = 0
local QUEUE_UPDATE_INTERVAL = 0.5 -- Update priorities every 0.5 seconds
local classAbilityPriorities = {}  -- Stores ability priorities by class/spec
local lastAbilityExecuted = nil    -- Last ability that was executed from the queue
local abilityHistory = {}         -- History of executed abilities for adaptive prioritization
local MAX_HISTORY_ENTRIES = 20     -- Maximum number of ability executions to track

-- Initialize module
function PriorityQueue:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Initialize class-specific priorities
    self:InitializeClassPriorities()
    
    -- Register events
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:RefreshPriorities()
        end
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:RefreshPriorities()
    end)
    
    API.PrintDebug("Priority Queue initialized")
    return true
end

-- Register settings
function PriorityQueue:RegisterSettings()
    ConfigRegistry:RegisterSettings("PriorityQueue", {
        queueSettings = {
            enablePriorityQueue = {
                displayName = "Enable Priority Queue",
                description = "Dynamically prioritize abilities",
                type = "toggle",
                default = true
            },
            adaptivePriorities = {
                displayName = "Adaptive Priorities",
                description = "Adjust priorities based on combat conditions",
                type = "toggle",
                default = true
            },
            overrideBaseRotation = {
                displayName = "Override Base Rotation",
                description = "Use priority queue instead of base rotation",
                type = "toggle",
                default = true
            },
            logPriorities = {
                displayName = "Log Priority Changes",
                description = "Log priority changes to the chat window",
                type = "toggle",
                default = false
            },
            maxQueueSize = {
                displayName = "Maximum Queue Size",
                description = "Maximum number of abilities in the queue",
                type = "slider",
                min = 5,
                max = 20,
                step = 1,
                default = 10
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("PriorityQueue", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function PriorityQueue:ApplySettings(settings)
    -- Apply queue settings
    enablePriorityQueue = settings.queueSettings.enablePriorityQueue
    adaptivePriorities = settings.queueSettings.adaptivePriorities
    overrideBaseRotation = settings.queueSettings.overrideBaseRotation
    logPriorities = settings.queueSettings.logPriorities
    maxQueueSize = settings.queueSettings.maxQueueSize
    
    API.PrintDebug("Priority Queue settings applied")
end

-- Update settings from external source
function PriorityQueue.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enablePriorityQueue ~= nil then
        enablePriorityQueue = newSettings.enablePriorityQueue
    end
    
    if newSettings.adaptivePriorities ~= nil then
        adaptivePriorities = newSettings.adaptivePriorities
    end
    
    if newSettings.overrideBaseRotation ~= nil then
        overrideBaseRotation = newSettings.overrideBaseRotation
    end
end

-- Initialize class-specific ability priorities
function PriorityQueue:InitializeClassPriorities()
    -- Warrior priorities
    classAbilityPriorities["WARRIOR"] = {
        -- Arms spec (1)
        [1] = {
            {id = 167105, name = "Colossus Smash", priority = 10, type = "offensive", conditions = {"executePhase", "burstWindow"}},
            {id = 260643, name = "Skullsplitter", priority = 20, type = "offensive", conditions = {"resourceBelow40"}},
            {id = 12294, name = "Mortal Strike", priority = 30, type = "offensive"},
            {id = 7384, name = "Overpower", priority = 40, type = "offensive"},
            {id = 1464, name = "Slam", priority = 50, type = "offensive", conditions = {"resourceAbove60"}},
            {id = 163201, name = "Execute", priority = 15, type = "offensive", conditions = {"executePhase"}},
            {id = 1719, name = "Recklessness", priority = 5, type = "cooldown", conditions = {"burstWindow"}},
            {id = 262161, name = "Warbreaker", priority = 25, type = "offensive", conditions = {"burstWindow", "aoeCondition"}}
        },
        -- Fury spec (2)
        [2] = {
            {id = 184367, name = "Rampage", priority = 10, type = "offensive", conditions = {"resourceAbove80"}},
            {id = 85288, name = "Raging Blow", priority = 30, type = "offensive"},
            {id = 5308, name = "Execute", priority = 15, type = "offensive", conditions = {"executePhase"}},
            {id = 23881, name = "Bloodthirst", priority = 25, type = "offensive"},
            {id = 1719, name = "Recklessness", priority = 5, type = "cooldown", conditions = {"burstWindow"}},
            {id = 118000, name = "Dragon Roar", priority = 35, type = "offensive", conditions = {"aoeCondition"}},
            {id = 315720, name = "Bladestorm", priority = 20, type = "offensive", conditions = {"aoeCondition", "burstWindow"}}
        },
        -- Protection spec (3)
        [3] = {
            {id = 6572, name = "Revenge", priority = 30, type = "offensive", conditions = {"resourceAbove60"}},
            {id = 23922, name = "Shield Slam", priority = 10, type = "offensive"},
            {id = 20243, name = "Devastate", priority = 50, type = "offensive"},
            {id = 6343, name = "Thunder Clap", priority = 20, type = "offensive", conditions = {"aoeCondition"}},
            {id = 1160, name = "Demoralizing Shout", priority = 25, type = "defensive"},
            {id = 12975, name = "Last Stand", priority = 5, type = "defensive", conditions = {"healthBelow30"}},
            {id = 871, name = "Shield Wall", priority = 5, type = "defensive", conditions = {"healthBelow20"}}
        }
    }
    
    -- Priest priorities
    classAbilityPriorities["PRIEST"] = {
        -- Discipline spec (1)
        [1] = {
            {id = 589, name = "Shadow Word: Pain", priority = 20, type = "offensive", conditions = {"targetDebuffMissing"}},
            {id = 47540, name = "Penance", priority = 10, type = "offensive"},
            {id = 214621, name = "Schism", priority = 15, type = "offensive", conditions = {"burstWindow"}},
            {id = 110744, name = "Divine Star", priority = 25, type = "offensive", conditions = {"aoeCondition"}},
            {id = 129250, name = "Power Word: Solace", priority = 30, type = "offensive"},
            {id = 8092, name = "Mind Blast", priority = 35, type = "offensive"},
            {id = 585, name = "Smite", priority = 40, type = "offensive"}
        },
        -- Holy spec (2)
        [2] = {
            {id = 14914, name = "Holy Fire", priority = 10, type = "offensive"},
            {id = 589, name = "Shadow Word: Pain", priority = 20, type = "offensive", conditions = {"targetDebuffMissing"}},
            {id = 88625, name = "Holy Word: Chastise", priority = 15, type = "offensive"},
            {id = 110744, name = "Divine Star", priority = 25, type = "offensive", conditions = {"aoeCondition"}},
            {id = 585, name = "Smite", priority = 30, type = "offensive"}
        },
        -- Shadow spec (3)
        [3] = {
            {id = 589, name = "Shadow Word: Pain", priority = 25, type = "offensive", conditions = {"targetDebuffMissing"}},
            {id = 34914, name = "Vampiric Touch", priority = 20, type = "offensive", conditions = {"targetDebuffMissing"}},
            {id = 263165, name = "Void Torrent", priority = 10, type = "offensive", conditions = {"burstWindow"}},
            {id = 8092, name = "Mind Blast", priority = 15, type = "offensive"},
            {id = 341374, name = "Damnation", priority = 5, type = "offensive", conditions = {"executePhase", "burstWindow"}},
            {id = 32379, name = "Shadow Word: Death", priority = 12, type = "offensive", conditions = {"executePhase"}},
            {id = 15407, name = "Mind Flay", priority = 30, type = "offensive"},
            {id = 205385, name = "Shadow Crash", priority = 18, type = "offensive", conditions = {"aoeCondition"}},
            {id = 228260, name = "Void Eruption", priority = 5, type = "offensive", conditions = {"burstWindow"}},
            {id = 319952, name = "Surrender to Madness", priority = 2, type = "offensive", conditions = {"burstWindow", "executePhase"}}
        }
    }
    
    -- Add more classes as needed for comprehensive coverage
    -- Example: Mage
    classAbilityPriorities["MAGE"] = {
        -- Arcane spec (1)
        [1] = {
            {id = 30451, name = "Arcane Blast", priority = 10, type = "offensive"},
            {id = 5143, name = "Arcane Missiles", priority = 15, type = "offensive", conditions = {"hasBuff"}},
            {id = 44425, name = "Arcane Barrage", priority = 20, type = "offensive", conditions = {"resourceAbove80"}},
            {id = 12042, name = "Arcane Power", priority = 5, type = "cooldown", conditions = {"burstWindow"}}
        },
        -- Fire spec (2)
        [2] = {
            {id = 133, name = "Fireball", priority = 20, type = "offensive"},
            {id = 108853, name = "Fire Blast", priority = 15, type = "offensive", conditions = {"hasProcBuff"}},
            {id = 11366, name = "Pyroblast", priority = 10, type = "offensive", conditions = {"hasProcBuff"}},
            {id = 190319, name = "Combustion", priority = 5, type = "cooldown", conditions = {"burstWindow"}}
        },
        -- Frost spec (3)
        [3] = {
            {id = 116, name = "Frostbolt", priority = 20, type = "offensive"},
            {id = 30455, name = "Ice Lance", priority = 10, type = "offensive", conditions = {"hasProcBuff"}},
            {id = 12472, name = "Icy Veins", priority = 5, type = "cooldown", conditions = {"burstWindow"}},
            {id = 84714, name = "Frozen Orb", priority = 15, type = "offensive", conditions = {"aoeCondition"}}
        }
    }
    
    -- Additional class priorities would be included similarly...
end

-- Refresh current priorities (called when spec changes, etc.)
function PriorityQueue:RefreshPriorities()
    -- Clear ability history when spec changes
    abilityHistory = {}
    
    -- Force queue update on next check
    priorityQueueLastUpdated = 0
    
    -- Update class-specific abilities
    -- More logic could be added here for talents, etc.
    
    API.PrintDebug("Priority Queue priorities refreshed")
end

-- Record ability execution for adaptive prioritization
function PriorityQueue:RecordAbilityExecution(abilityId, successful)
    -- Skip if not using adaptive priorities
    if not adaptivePriorities then return end
    
    -- Record in history
    table.insert(abilityHistory, {
        id = abilityId,
        time = GetTime(),
        successful = successful
    })
    
    -- Trim history if it gets too long
    while #abilityHistory > MAX_HISTORY_ENTRIES do
        table.remove(abilityHistory, 1)
    end
    
    -- If successful, this becomes our last executed ability
    if successful then
        lastAbilityExecuted = abilityId
    end
    
    -- In a real implementation, this would adaptively adjust priorities based on success/failure
    -- For example, if an ability consistently fails, lower its priority
end

-- Get the current priority list for player's class and spec
function PriorityQueue:GetCurrentPriorityList()
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    if not playerClass or not playerSpec then
        return {}
    end
    
    -- Get the base priority list for this class/spec
    if not classAbilityPriorities[playerClass] or 
       not classAbilityPriorities[playerClass][playerSpec] then
        return {}
    end
    
    -- Clone the list to avoid modifying the original
    local priorityList = {}
    for i, ability in ipairs(classAbilityPriorities[playerClass][playerSpec]) do
        priorityList[i] = {
            id = ability.id,
            name = ability.name,
            priority = ability.priority,
            type = ability.type,
            conditions = ability.conditions
        }
    end
    
    return priorityList
end

-- Check if an ability should be executed based on conditions
function PriorityQueue:ShouldExecuteAbility(ability, combatState)
    -- If no conditions, always execute
    if not ability.conditions then
        return true
    end
    
    -- Check each condition
    for _, condition in ipairs(ability.conditions) do
        if condition == "executePhase" and not combatState.executePhase then
            return false
        elseif condition == "burstWindow" and not combatState.burstWindow then
            return false
        elseif condition == "aoeCondition" and combatState.enemyCount < 3 then
            return false
        elseif condition == "resourceBelow40" and combatState.resource >= 40 then
            return false
        elseif condition == "resourceAbove60" and combatState.resource <= 60 then
            return false
        elseif condition == "resourceAbove80" and combatState.resource <= 80 then
            return false
        elseif condition == "healthBelow30" and combatState.health >= 30 then
            return false
        elseif condition == "healthBelow20" and combatState.health >= 20 then
            return false
        elseif condition == "targetDebuffMissing" then
            -- This would need to check if the specific debuff is missing
            -- In a full implementation, this would be more sophisticated
            -- For now, we'll just allow it
        elseif condition == "hasBuff" or condition == "hasProcBuff" then
            -- This would check for specific buffs
            -- Again, this would be more sophisticated in a real implementation
        end
    end
    
    -- If all conditions passed or were skipped, return true
    return true
end

-- Sort abilities by priority (lower number = higher priority)
function PriorityQueue:SortAbilitiesByPriority(abilities)
    table.sort(abilities, function(a, b) return a.priority < b.priority end)
    return abilities
end

-- Process the queue for a specific class/spec
function PriorityQueue.ProcessQueue(playerClass, playerSpec, combatState)
    -- Skip if disabled
    if not enablePriorityQueue then
        return nil
    end
    
    -- Force update if it's been too long
    if GetTime() - priorityQueueLastUpdated > QUEUE_UPDATE_INTERVAL then
        PriorityQueue:RefreshPriorities()
        priorityQueueLastUpdated = GetTime()
    end
    
    -- Get current priority list
    local priorities = PriorityQueue:GetCurrentPriorityList()
    if #priorities == 0 then
        return nil
    end
    
    -- Filter by conditions and check if usable
    local usablePriorities = {}
    for _, ability in ipairs(priorities) do
        if PriorityQueue:ShouldExecuteAbility(ability, combatState) and 
           API.IsSpellKnown(ability.id) and 
           API.IsSpellUsable(ability.id) then
            table.insert(usablePriorities, ability)
        end
    end
    
    -- Sort by priority
    usablePriorities = PriorityQueue:SortAbilitiesByPriority(usablePriorities)
    
    -- Get the highest priority ability
    if #usablePriorities > 0 then
        local topAbility = usablePriorities[1]
        
        -- Record that we're trying to use this ability
        PriorityQueue:RecordAbilityExecution(topAbility.id, true)
        
        -- Return the ability to use
        return {
            id = topAbility.id,
            target = "target"  -- Most offensive abilities target the enemy
        }
    end
    
    return nil
end

-- Return module
return PriorityQueue