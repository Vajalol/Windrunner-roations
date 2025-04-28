-- MovementManager.lua
-- Handles player movement, positioning, and pathing
local addonName, WR = ...
local MovementManager = {}
WR.MovementManager = MovementManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local enableMovementOptimization = true
local lastMovementAction = 0
local MIN_MOVEMENT_INTERVAL = 0.5  -- Minimum seconds between movement commands
local playerPosition = {x = 0, y = 0, z = 0}
local targetPosition = {x = 0, y = 0, z = 0}
local safeZones = {}
local dangerZones = {}
local pathingGraph = {}
local isMoving = false
local moveTargetGUID = nil
local currentPath = {}
local waypointIndex = 1
local currentNodeIndex = 1
local isFollowingPath = false
local lastPositionUpdate = 0
local POSITION_UPDATE_INTERVAL = 0.2
local playerClass = ""

-- Class-specific movement abilities
local movementAbilities = {
    ["WARRIOR"] = {
        { id = 6544, name = "Heroic Leap", type = "leap", range = 40 },
        { id = 100, name = "Charge", type = "charge", range = 25, requiresTarget = true },
        { id = 52174, name = "Heroic Throw", type = "throw", range = 30, requiresTarget = true }
    },
    ["PALADIN"] = {
        { id = 190784, name = "Divine Steed", type = "speed", duration = 3 },
        { id = 215661, name = "Blessing of the Steed", type = "speed", duration = 8, target = "friendly" }
    },
    ["HUNTER"] = {
        { id = 781, name = "Disengage", type = "disengage", range = 20 },
        { id = 5118, name = "Aspect of the Cheetah", type = "speed", duration = 9 },
        { id = 186257, name = "Aspect of the Cheetah", type = "speed", duration = 3 },
        { id = 109304, name = "Exhilaration", type = "combined", duration = 4 }
    },
    ["ROGUE"] = {
        { id = 36554, name = "Shadowstep", type = "teleport", range = 25, requiresTarget = true },
        { id = 2983, name = "Sprint", type = "speed", duration = 8 },
        { id = 1856, name = "Vanish", type = "stealth" },
        { id = 185311, name = "Crimson Vial", type = "selfheal" }
    },
    ["PRIEST"] = {
        { id = 8122, name = "Psychic Scream", type = "crowd_control", range = 8 },
        { id = 73325, name = "Leap of Faith", type = "pull", range = 40, target = "friendly" },
        { id = 121536, name = "Angelic Feather", type = "ground_speed", range = 30, duration = 5 },
        { id = 214121, name = "Body and Mind", type = "speed", duration = 3, target = "friendly" }
    },
    ["DEATHKNIGHT"] = {
        { id = 49576, name = "Death Grip", type = "pull", range = 30, target = "enemy" },
        { id = 48265, name = "Death's Advance", type = "speed", duration = 8 },
        { id = 43265, name = "Death and Decay", type = "ground_aoe", range = 30 },
        { id = 212552, name = "Wraith Walk", type = "speed", duration = 4 }
    },
    ["SHAMAN"] = {
        { id = 58875, name = "Spirit Walk", type = "speed", duration = 8 },
        { id = 2645, name = "Ghost Wolf", type = "transform", duration = 0 },
        { id = 79206, name = "Spiritwalker's Grace", type = "castmoving", duration = 15 }
    },
    ["MAGE"] = {
        { id = 1953, name = "Blink", type = "teleport", range = 20 },
        { id = 212653, name = "Shimmer", type = "teleport", range = 20 },
        { id = 108839, name = "Ice Floes", type = "castmoving", duration = 15 },
        { id = 66, name = "Invisibility", type = "stealth", duration = 20 }
    },
    ["WARLOCK"] = {
        { id = 48020, name = "Demonic Circle: Teleport", type = "teleport" },
        { id = 48018, name = "Demonic Circle", type = "place" },
        { id = 111400, name = "Burning Rush", type = "speed", duration = 0, healthCost = true }
    },
    ["MONK"] = {
        { id = 115008, name = "Chi Torpedo", type = "dash", range = 20 },
        { id = 109132, name = "Roll", type = "dash", range = 15 },
        { id = 115178, name = "Resuscitate", type = "revive", target = "friendly" },
        { id = 116841, name = "Tiger's Lust", type = "speed", duration = 6, target = "friendly" }
    },
    ["DRUID"] = {
        { id = 1850, name = "Dash", type = "speed", duration = 10 },
        { id = 252216, name = "Tiger Dash", type = "speed", duration = 5 },
        { id = 102401, name = "Wild Charge", type = "charge", range = 25, requiresTarget = true },
        { id = 5487, name = "Bear Form", type = "transform" },
        { id = 768, name = "Cat Form", type = "transform" },
        { id = 783, name = "Travel Form", type = "transform" },
        { id = 102359, name = "Mass Entanglement", type = "crowd_control", range = 35 }
    },
    ["DEMONHUNTER"] = {
        { id = 195072, name = "Fel Rush", type = "dash", range = 15 },
        { id = 198793, name = "Vengeful Retreat", type = "disengage", range = 15 },
        { id = 131347, name = "Glide", type = "slowfall" },
        { id = 200166, name = "Metamorphosis", type = "leap", range = 30 }
    },
    ["EVOKER"] = {
        { id = 358267, name = "Hover", type = "slowfall" },
        { id = 361309, name = "Wing Buffet", type = "knockback", range = 10 },
        { id = 358385, name = "Landslide", type = "dash", range = 15 }
    }
}

-- Different types of movement strategies
local movementStrategies = {
    ["melee"] = {
        idealRange = 5,
        maxRange = 8,
        maintainBackPosition = true,
        priorityAbilityTypes = {"charge", "leap", "dash"}
    },
    ["ranged"] = {
        idealRange = 25,
        maxRange = 35,
        maintainBackPosition = false,
        priorityAbilityTypes = {"teleport", "speed", "disengage"}
    },
    ["kite"] = {
        idealRange = 15,
        maxRange = 25,
        maintainBackPosition = true,
        kiteTarget = true,
        priorityAbilityTypes = {"speed", "disengage", "teleport"}
    },
    ["tank"] = {
        idealRange = 5,
        maxRange = 8,
        maintainBackPosition = false,
        faceTarget = true,
        priorityAbilityTypes = {"charge", "leap", "pull"}
    }
}

-- Initialize module
function MovementManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Get player class
    playerClass = select(2, UnitClass("player"))
    
    -- Register events for position tracking
    API.RegisterEvent("PLAYER_STARTED_MOVING", function()
        isMoving = true
    end)
    
    API.RegisterEvent("PLAYER_STOPPED_MOVING", function()
        isMoving = false
    end)
    
    -- Register combat events for danger detection
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLog()
    end)
    
    -- Register for world map updates
    API.RegisterEvent("WORLD_MAP_UPDATE", function()
        self:UpdatePathingData()
    end)
    
    -- Register for zone changes
    API.RegisterEvent("ZONE_CHANGED", function()
        self:UpdateZoneData()
    end)
    
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:UpdateZoneData()
    end)
    
    -- Initial update
    self:UpdatePlayerPosition()
    self:UpdateZoneData()
    
    API.PrintDebug("Movement Manager initialized")
    return true
end

-- Register settings
function MovementManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("MovementManager", {
        movementSettings = {
            enableMovementOptimization = {
                displayName = "Enable Movement Optimization",
                description = "Automatically optimize player movement and positioning",
                type = "toggle",
                default = true
            },
            movementStrategy = {
                displayName = "Movement Strategy",
                description = "Select movement strategy based on your role",
                type = "dropdown",
                options = {"Auto", "Melee", "Ranged", "Kite", "Tank"},
                default = 1
            },
            maintainRange = {
                displayName = "Maintain Range",
                description = "Automatically maintain optimal range from target",
                type = "toggle",
                default = true
            },
            avoidDanger = {
                displayName = "Avoid Danger Zones",
                description = "Automatically move away from dangerous ground effects",
                type = "toggle",
                default = true
            },
            useMovementAbilities = {
                displayName = "Use Movement Abilities",
                description = "Use class movement abilities for positioning",
                type = "toggle",
                default = true
            },
            followGroupInCities = {
                displayName = "Follow Group in Cities",
                description = "Automatically follow group members when in cities",
                type = "toggle",
                default = false
            },
            followGroupLeader = {
                displayName = "Follow Group Leader",
                description = "Automatically follow the group leader outside of combat",
                type = "toggle",
                default = false
            },
            pathfindInCombat = {
                displayName = "Pathfind In Combat",
                description = "Use pathfinding to navigate around obstacles during combat",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("MovementManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function MovementManager:ApplySettings(settings)
    -- Apply movement settings
    enableMovementOptimization = settings.movementSettings.enableMovementOptimization
    local strategyIndex = settings.movementSettings.movementStrategy
    
    -- Convert strategy dropdown index to strategy name
    local strategyNames = {"auto", "melee", "ranged", "kite", "tank"}
    selectedStrategy = strategyNames[strategyIndex] or "auto"
    
    maintainRange = settings.movementSettings.maintainRange
    avoidDanger = settings.movementSettings.avoidDanger
    useMovementAbilities = settings.movementSettings.useMovementAbilities
    followGroupInCities = settings.movementSettings.followGroupInCities
    followGroupLeader = settings.movementSettings.followGroupLeader
    pathfindInCombat = settings.movementSettings.pathfindInCombat
    
    API.PrintDebug("Movement Manager settings applied")
end

-- Update settings from external source
function MovementManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enableMovementOptimization ~= nil then
        enableMovementOptimization = newSettings.enableMovementOptimization
    end
    
    if newSettings.selectedStrategy ~= nil then
        selectedStrategy = newSettings.selectedStrategy
    end
end

-- Update player position
function MovementManager:UpdatePlayerPosition()
    -- Get player position
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    
    local x, y = pos:GetXY()
    local _, _, z = WorldToScreen(x, y, 0)
    
    -- Store position
    playerPosition = {
        x = x,
        y = y,
        z = z or 0,
        mapID = mapID,
        time = GetTime()
    }
    
    -- Update target position if we have a target
    if UnitExists("target") then
        self:UpdateTargetPosition()
    end
    
    lastPositionUpdate = GetTime()
end

-- Update target position
function MovementManager:UpdateTargetPosition()
    -- Skip if no target
    if not UnitExists("target") then
        return
    end
    
    -- Get target position
    local targetX, targetY, targetZ
    
    -- Try to get position from game API
    if API.GetObjectPosition then
        targetX, targetY, targetZ = API.GetObjectPosition("target")
    end
    
    -- If API didn't work, use alternative method
    if not targetX or not targetY then
        -- Fallback method - estimate based on distance and angle
        local facing = GetPlayerFacing()
        local distance = CheckInteractDistance("target", 2) and 10 or 30 -- approximate
        
        -- Calculate position based on player position, facing and distance
        targetX = playerPosition.x + math.cos(facing) * distance
        targetY = playerPosition.y + math.sin(facing) * distance
        targetZ = playerPosition.z
    end
    
    -- Store position
    targetPosition = {
        x = targetX,
        y = targetY,
        z = targetZ or playerPosition.z,
        guid = UnitGUID("target"),
        time = GetTime()
    }
}

-- Update zone data including safe and danger zones
function MovementManager:UpdateZoneData()
    -- Reset zone data
    safeZones = {}
    dangerZones = {}
    
    -- Get current zone info
    local mapID = C_Map.GetBestMapForUnit("player")
    local zoneName = GetZoneText()
    
    -- TODO: Add zone-specific safe and danger zones
    -- This would be implemented with specific knowledge of dungeon mechanics, etc.
    
    API.PrintDebug("Updated zone data for: " .. zoneName)
end

-- Update pathing graph for current zone
function MovementManager:UpdatePathingData()
    -- Reset pathing data
    pathingGraph = {}
    
    -- TODO: Implement zone-specific pathing data
    -- This would be much more sophisticated in a real implementation
    
    API.PrintDebug("Updated pathing data")
end

-- Process combat log for danger detection
function MovementManager:ProcessCombatLog()
    -- TODO: Process combat log to detect danger zones
    -- Example: detect ground effects, AoE spells, etc.
    
    -- For now, this is a placeholder
end

-- Calculate distance between two positions
function MovementManager:GetDistance(pos1, pos2)
    return math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2 + (pos2.z - pos1.z)^2)
end

-- Find a path between current position and target
function MovementManager:FindPath(startPos, endPos)
    -- TODO: Implement A* pathfinding algorithm
    -- For now, return a direct path
    
    return {
        {x = startPos.x, y = startPos.y, z = startPos.z},
        {x = endPos.x, y = endPos.y, z = endPos.z}
    }
end

-- Check if position is in a danger zone
function MovementManager:IsPositionDangerous(pos)
    -- Check each danger zone
    for _, zone in ipairs(dangerZones) do
        -- Calculate distance from position to center of danger zone
        local distance = self:GetDistance(pos, zone)
        
        -- If distance is less than radius, position is in danger zone
        if distance < zone.radius then
            return true
        end
    end
    
    return false
end

-- Find a safe position near target
function MovementManager:FindSafePosition(targetPos, strategy)
    -- Get strategy configuration
    local strategyConfig = movementStrategies[strategy] or movementStrategies["ranged"]
    
    -- Start with the ideal range
    local idealRange = strategyConfig.idealRange
    local maxRange = strategyConfig.maxRange
    
    -- Calculate positions around the target at the ideal range
    local positions = {}
    local numPositions = 8  -- Check 8 positions around the target
    
    for i = 1, numPositions do
        -- Calculate angle
        local angle = (i - 1) * (2 * math.pi / numPositions)
        
        -- Calculate position
        local x = targetPos.x + math.cos(angle) * idealRange
        local y = targetPos.y + math.sin(angle) * idealRange
        local z = targetPos.z
        
        -- Create position
        local pos = {x = x, y = y, z = z}
        
        -- Check if position is safe
        local isSafe = not self:IsPositionDangerous(pos)
        
        -- If position is safe, add to list
        if isSafe then
            -- If we want to maintain back position, prioritize positions behind target
            if strategyConfig.maintainBackPosition then
                -- Get target's facing
                local targetFacing = 0  -- Default placeholder
                
                -- TODO: Implement getting target's facing
                -- This would be more sophisticated in a real implementation
                
                -- Calculate angle from target to position
                local angleToPos = math.atan2(y - targetPos.y, x - targetPos.x)
                
                -- Calculate angle difference
                local angleDiff = math.abs(angleToPos - targetFacing)
                while angleDiff > math.pi do
                    angleDiff = angleDiff - 2 * math.pi
                end
                angleDiff = math.abs(angleDiff)
                
                -- If angle difference is within 90 degrees of opposite target facing, position is behind
                if angleDiff > math.pi / 2 then
                    -- Higher priority for positions behind target
                    pos.priority = 10
                else
                    pos.priority = 50
                end
            else
                pos.priority = 30
            end
            
            -- Add to positions list
            table.insert(positions, pos)
        end
    end
    
    -- If no safe positions at ideal range, try other ranges
    if #positions == 0 then
        -- Try closer ranges first, then further
        for range = idealRange - 2, maxRange, 2 do
            for i = 1, numPositions do
                -- Calculate angle
                local angle = (i - 1) * (2 * math.pi / numPositions)
                
                -- Calculate position
                local x = targetPos.x + math.cos(angle) * range
                local y = targetPos.y + math.sin(angle) * range
                local z = targetPos.z
                
                -- Create position
                local pos = {x = x, y = y, z = z}
                
                -- Check if position is safe
                local isSafe = not self:IsPositionDangerous(pos)
                
                -- If position is safe, add to list
                if isSafe then
                    -- Further from ideal range = lower priority
                    pos.priority = 30 + math.abs(range - idealRange) * 5
                    
                    -- Add to positions list
                    table.insert(positions, pos)
                end
            end
            
            -- If we found at least one position, stop searching
            if #positions > 0 then
                break
            end
        end
    end
    
    -- Sort positions by priority (lower = higher priority)
    table.sort(positions, function(a, b) return a.priority < b.priority end)
    
    -- Return the best position, or nil if none found
    return positions[1]
end

-- Get the best movement ability for the current situation
function MovementManager:GetBestMovementAbility(distanceToTarget, strategy)
    -- Skip if not using movement abilities
    if not useMovementAbilities then
        return nil
    end
    
    -- Get strategy configuration
    local strategyConfig = movementStrategies[strategy] or movementStrategies["ranged"]
    
    -- Get priority ability types for this strategy
    local priorityTypes = strategyConfig.priorityAbilityTypes
    
    -- Get abilities for player class
    local abilities = movementAbilities[playerClass]
    if not abilities then
        return nil
    end
    
    -- Filter abilities by usability
    local usableAbilities = {}
    for _, ability in ipairs(abilities) do
        -- Check if spell is known and usable
        if API.IsSpellKnown(ability.id) and API.IsSpellUsable(ability.id) then
            -- Skip abilities that require a target if we don't have one
            if not (ability.requiresTarget and not UnitExists("target")) then
                -- Calculate a priority score based on ability type
                local typePriority = 100  -- Default low priority
                
                -- Check if this type is in priority types
                for i, priorityType in ipairs(priorityTypes) do
                    if ability.type == priorityType then
                        typePriority = i * 10  -- Higher priority for earlier types in the list
                        break
                    end
                end
                
                -- Adjust priority based on distance
                if ability.type == "charge" or ability.type == "leap" then
                    -- These are better for covering larger distances
                    if distanceToTarget > 10 then
                        typePriority = typePriority - 10  -- Higher priority
                    end
                elseif ability.type == "teleport" then
                    -- Teleports are good for any distance within range
                    typePriority = typePriority - 5
                elseif ability.type == "speed" then
                    -- Speed boosts are better for medium distances
                    if distanceToTarget > 5 and distanceToTarget < 20 then
                        typePriority = typePriority - 5
                    end
                end
                
                -- Store with priority
                table.insert(usableAbilities, {
                    id = ability.id,
                    name = ability.name,
                    type = ability.type,
                    range = ability.range,
                    target = ability.target or "none",
                    requiresTarget = ability.requiresTarget or false,
                    priority = typePriority
                })
            end
        end
    end
    
    -- Sort by priority (lower = higher priority)
    table.sort(usableAbilities, function(a, b) return a.priority < b.priority end)
    
    -- Return the best ability, or nil if none found
    return usableAbilities[1]
end

-- Determine the appropriate movement strategy based on class, spec, and combat situation
function MovementManager:DetermineStrategy(combatState)
    -- If strategy is set to "auto", determine based on class/spec
    if selectedStrategy == "auto" then
        local playerClass = select(2, UnitClass("player"))
        local playerSpec = GetSpecialization() or 0
        
        -- Determine strategy based on class and spec
        if playerClass == "WARRIOR" then
            if playerSpec == 3 then
                return "tank"  -- Protection spec
            else
                return "melee"  -- Arms or Fury
            end
        elseif playerClass == "PALADIN" then
            if playerSpec == 2 then
                return "tank"  -- Protection spec
            elseif playerSpec == 1 then
                return "ranged"  -- Holy spec
            else
                return "melee"  -- Retribution
            end
        elseif playerClass == "HUNTER" then
            return "ranged"
        elseif playerClass == "ROGUE" then
            return "melee"
        elseif playerClass == "PRIEST" then
            return "ranged"
        elseif playerClass == "DEATHKNIGHT" then
            if playerSpec == 1 then
                return "tank"  -- Blood spec
            else
                return "melee"  -- Frost or Unholy
            end
        elseif playerClass == "SHAMAN" then
            if playerSpec == 2 then
                return "melee"  -- Enhancement
            else
                return "ranged"  -- Elemental or Restoration
            end
        elseif playerClass == "MAGE" then
            return "ranged"
        elseif playerClass == "WARLOCK" then
            return "ranged"
        elseif playerClass == "MONK" then
            if playerSpec == 1 then
                return "tank"  -- Brewmaster
            elseif playerSpec == 2 then
                return "ranged"  -- Mistweaver
            else
                return "melee"  -- Windwalker
            end
        elseif playerClass == "DRUID" then
            if playerSpec == 3 then
                return "tank"  -- Guardian
            elseif playerSpec == 4 then
                return "ranged"  -- Restoration
            elseif playerSpec == 1 then
                return "ranged"  -- Balance
            else
                return "melee"  -- Feral
            end
        elseif playerClass == "DEMONHUNTER" then
            if playerSpec == 2 then
                return "tank"  -- Vengeance
            else
                return "melee"  -- Havoc
            end
        elseif playerClass == "EVOKER" then
            if playerSpec == 2 then
                return "ranged"  -- Preservation
            else
                return "ranged"  -- Devastation or Augmentation
            end
        end
        
        -- Default to ranged if we couldn't determine
        return "ranged"
    else
        -- Use the explicitly selected strategy
        return selectedStrategy
    end
end

-- Process movement based on combat state
function MovementManager.ProcessMovement(combatState)
    -- Skip if disabled
    if not enableMovementOptimization then
        return nil
    end
    
    -- Skip if too soon after last movement action
    if GetTime() - lastMovementAction < MIN_MOVEMENT_INTERVAL then
        return nil
    end
    
    -- Update player position if needed
    if GetTime() - lastPositionUpdate > POSITION_UPDATE_INTERVAL then
        MovementManager:UpdatePlayerPosition()
    end
    
    -- Handle different contexts based on combat state
    if combatState.inCombat then
        -- Combat movement
        return MovementManager:ProcessCombatMovement(combatState)
    else
        -- Non-combat movement
        return MovementManager:ProcessNonCombatMovement(combatState)
    end
end

-- Process movement during combat
function MovementManager:ProcessCombatMovement(combatState)
    -- Skip if no target
    if not UnitExists("target") then
        return nil
    end
    
    -- Determine movement strategy
    local strategy = self:DetermineStrategy(combatState)
    
    -- Update target position
    self:UpdateTargetPosition()
    
    -- Calculate distance to target
    local distanceToTarget = self:GetDistance(playerPosition, targetPosition)
    
    -- Get strategy configuration
    local strategyConfig = movementStrategies[strategy] or movementStrategies["ranged"]
    local idealRange = strategyConfig.idealRange
    local maxRange = strategyConfig.maxRange
    
    -- Check if we need to move closer/further to maintain range
    if maintainRange then
        -- If we're too far away, move closer
        if distanceToTarget > maxRange then
            -- Find safe position near target
            local safePos = self:FindSafePosition(targetPosition, strategy)
            
            -- If we found a safe position, move there
            if safePos then
                -- Try to use movement ability first
                local movementAbility = self:GetBestMovementAbility(distanceToTarget, strategy)
                
                if movementAbility then
                    lastMovementAction = GetTime()
                    
                    -- Return movement ability
                    if movementAbility.requiresTarget then
                        return {
                            id = movementAbility.id,
                            target = "target"
                        }
                    else
                        return {
                            id = movementAbility.id,
                            target = "player"
                        }
                    end
                end
                
                -- Return movement command
                lastMovementAction = GetTime()
                
                return {
                    move = true,
                    x = safePos.x,
                    y = safePos.y,
                    z = safePos.z
                }
            end
        -- If we're too close, move away (for ranged/kite strategies)
        elseif distanceToTarget < idealRange - 2 and (strategy == "ranged" or strategy == "kite") then
            -- For kite strategy, try to move away from target
            local angle = math.atan2(playerPosition.y - targetPosition.y, playerPosition.x - targetPosition.x)
            
            -- Calculate position further away
            local newX = playerPosition.x + math.cos(angle) * 5
            local newY = playerPosition.y + math.sin(angle) * 5
            local newZ = playerPosition.z
            
            -- Create position
            local retreatPos = {x = newX, y = newY, z = newZ}
            
            -- Check if position is safe
            if not self:IsPositionDangerous(retreatPos) then
                -- Try to use movement ability first
                local movementAbility = self:GetBestMovementAbility(distanceToTarget, strategy)
                
                if movementAbility and (movementAbility.type == "disengage" or movementAbility.type == "teleport" or movementAbility.type == "speed") then
                    lastMovementAction = GetTime()
                    
                    -- Return movement ability
                    return {
                        id = movementAbility.id,
                        target = "player"
                    }
                end
                
                -- Return movement command
                lastMovementAction = GetTime()
                
                return {
                    move = true,
                    x = retreatPos.x,
                    y = retreatPos.y,
                    z = retreatPos.z
                }
            end
        end
    end
    
    -- Check if we're in danger and need to move
    if avoidDanger and self:IsPositionDangerous(playerPosition) then
        -- Try to find a safe position
        local safePos = self:FindSafePosition(targetPosition, strategy)
        
        -- If we found a safe position, move there
        if safePos then
            -- Try to use movement ability first
            local movementAbility = self:GetBestMovementAbility(5, strategy)
            
            if movementAbility and (movementAbility.type == "teleport" or movementAbility.type == "disengage" or movementAbility.type == "dash") then
                lastMovementAction = GetTime()
                
                -- Return movement ability
                return {
                    id = movementAbility.id,
                    target = "player"
                }
            end
            
            -- Return movement command
            lastMovementAction = GetTime()
            
            return {
                move = true,
                x = safePos.x,
                y = safePos.y,
                z = safePos.z
            }
        end
    end
    
    return nil
end

-- Process movement outside of combat
function MovementManager:ProcessNonCombatMovement(combatState)
    -- Handle following group leader if enabled
    if followGroupLeader and IsInGroup() and not IsInRaid() then
        local leader = "party1"
        if UnitIsGroupLeader("player") then
            -- Player is leader, don't follow
            return nil
        end
        
        -- Find group leader
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and UnitIsGroupLeader(unit) then
                leader = unit
                break
            end
        end
        
        -- If leader exists and is not player
        if UnitExists(leader) and not UnitIsUnit(leader, "player") then
            -- Get leader position
            local leaderX, leaderY, leaderZ
            
            -- Try to get position from API
            if API.GetObjectPosition then
                leaderX, leaderY, leaderZ = API.GetObjectPosition(leader)
            end
            
            -- If we got position, check distance
            if leaderX and leaderY then
                local leaderPos = {x = leaderX, y = leaderY, z = leaderZ or 0}
                local distance = self:GetDistance(playerPosition, leaderPos)
                
                -- If leader is too far away, follow
                if distance > 10 then
                    -- Check if we're in city
                    local inCity = not combatState.inCombat and IsResting()
                    
                    -- Skip if in city and followGroupInCities disabled
                    if inCity and not followGroupInCities then
                        return nil
                    end
                    
                    -- Try to use movement ability first
                    local movementAbility = self:GetBestMovementAbility(distance, "melee")
                    
                    if movementAbility then
                        lastMovementAction = GetTime()
                        
                        -- Return movement ability
                        return {
                            id = movementAbility.id,
                            target = leader
                        }
                    end
                    
                    -- Return follow command
                    lastMovementAction = GetTime()
                    
                    return {
                        follow = true,
                        target = leader
                    }
                end
            end
        end
    end
    
    return nil
end

-- Return module
return MovementManager