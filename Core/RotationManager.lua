------------------------------------------
-- WindrunnerRotations - Rotation Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local RotationManager = {}
WR.RotationManager = RotationManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local PerformanceManager = WR.PerformanceManager
local AntiDetectionSystem = WR.AntiDetectionSystem
local ErrorHandler = WR.ErrorHandler
local CombatAnalysis = WR.CombatAnalysis
local PvPManager = WR.PvPManager
local ItemManager = WR.ItemManager
local RacialsManager = WR.RacialsManager
local BuffManager = WR.BuffManager
local DispelManager = WR.DispelManager
local PriorityQueue = WR.PriorityQueue

-- Rotation data
local isEnabled = true
local rotationFrame = nil
local updateFrequency = 0.01 -- Update rotation every 0.01 seconds
local lastUpdate = 0
local activeRotation = nil
local rotations = {}
local rotationActive = false
local inCombat = false
local executePhase = false
local adlExecuting = false
local nextSpellInfo = nil
local nextSpellCooldown = 0
local rotationTracking = {
    spellsExecuted = {},
    lastSpell = nil,
    startTime = 0,
    executionCount = 0,
    successCount = 0,
    failCount = 0
}
local lastRotationError = nil
local maxRotationErrors = 10
local rotationErrorCount = 0
local lastRotationExecuteTime = 0
local rotationExecutionTime = 0
local pauseRotation = false
local rotationMode = "automatic" -- "automatic", "semiAutomatic", "oneButton", "manual"
local lastTarget = nil
local smartTargeting = true
local aoeEnabled = true
local aoeDetectionRange = 8
local smartAoeThreshold = 3
local useAdvancedConditions = true
local useTrinkets = true
local useDefensives = true
local useMovementAbilities = true
local useInterrupts = true
local useCrowdControl = true
local useCooldowns = true
local useAuxiliaryAbilities = true
local lastTargetChangeTime = 0
local GCD_BUFFER = 0.1 -- Buffer time for GCD checks
local ACTION_THROTTLE = 0.1 -- Minimum time between actions
local currentRotationState = {
    health = 100,
    resource = 0,
    targetHealth = 0,
    targetCount = 0,
    cooldownsAvailable = {},
    buffsActive = {},
    debuffsActive = {},
    executePhase = false,
    spec = 0
}
local recentActions = {}
local MAX_RECENT_ACTIONS = 20
local currentAPL = {}
local lastAPLRefresh = 0
local APL_REFRESH_INTERVAL = 1.0 -- Refresh APL every 1 second
local rotationCache = {}
local actionTypes = {
    SPELL = "spell",
    ITEM = "item",
    MACRO = "macro",
    STOP = "stop",
    WAIT = "wait",
    TARGET = "target",
    FOCUS = "focus"
}
local combatMetrics = {
    startTime = 0,
    endTime = 0,
    dps = 0,
    damageDone = 0,
    damageBreakdown = {},
    successfulCasts = 0,
    failedCasts = 0,
    rotationEfficiency = 0,
    averageExecuteTime = 0,
    bestAction = nil,
    worstAction = nil
}

-- Initialize the Rotation Manager
function RotationManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create rotation frame
    self:CreateRotationFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Register built-in rotations
    self:RegisterBuiltInRotations()
    
    -- Register command
    self:RegisterSlashCommands()
    
    API.PrintDebug("Rotation Manager initialized")
    return true
end

-- Register settings
function RotationManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("RotationManager", {
        generalSettings = {
            enableRotation = {
                displayName = "Enable Rotation",
                description = "Enable automated rotation",
                type = "toggle",
                default = true
            },
            rotationMode = {
                displayName = "Rotation Mode",
                description = "How the rotation should execute",
                type = "dropdown",
                options = {"Automatic", "Semi-Automatic", "One Button", "Manual"},
                default = "Automatic"
            },
            updateFrequency = {
                displayName = "Update Frequency",
                description = "How often the rotation updates (seconds)",
                type = "slider",
                min = 0.01,
                max = 0.1,
                step = 0.01,
                default = 0.01
            },
            smartTargeting = {
                displayName = "Smart Targeting",
                description = "Automatically select the best target",
                type = "toggle",
                default = true
            }
        },
        combatSettings = {
            aoeEnabled = {
                displayName = "Enable AoE",
                description = "Enable multi-target abilities when appropriate",
                type = "toggle",
                default = true
            },
            aoeThreshold = {
                displayName = "AoE Threshold",
                description = "Number of targets needed to use AoE abilities",
                type = "slider",
                min = 2,
                max = 6,
                step = 1,
                default = 3
            },
            aoeDetectionRange = {
                displayName = "AoE Detection Range",
                description = "Range to detect multiple targets for AoE (yards)",
                type = "slider",
                min = 5,
                max = 15,
                step = 1,
                default = 8
            },
            useTrinkets = {
                displayName = "Use Trinkets",
                description = "Automatically use trinkets",
                type = "toggle",
                default = true
            },
            useDefensives = {
                displayName = "Use Defensives",
                description = "Automatically use defensive abilities",
                type = "toggle",
                default = true
            },
            useInterrupts = {
                displayName = "Use Interrupts",
                description = "Automatically interrupt enemy casts",
                type = "toggle",
                default = true
            },
            useCrowdControl = {
                displayName = "Use Crowd Control",
                description = "Automatically use crowd control abilities",
                type = "toggle",
                default = true
            },
            useCooldowns = {
                displayName = "Use Cooldowns",
                description = "Automatically use major cooldowns",
                type = "toggle",
                default = true
            },
            useAuxiliaryAbilities = {
                displayName = "Use Auxiliary Abilities",
                description = "Use utility and auxiliary abilities",
                type = "toggle",
                default = true
            },
            useRacials = {
                displayName = "Use Racial Abilities",
                description = "Automatically use racial abilities",
                type = "toggle",
                default = true
            },
            useConsumables = {
                displayName = "Use Consumables",
                description = "Automatically use health/mana potions and healthstones",
                type = "toggle",
                default = true
            },
            useAutoDispel = {
                displayName = "Auto-Dispel",
                description = "Automatically dispel harmful effects on friendly targets",
                type = "toggle",
                default = true
            },
            useGroupBuffs = {
                displayName = "Track Group Buffs",
                description = "Automatically track and cast missing group buffs",
                type = "toggle",
                default = true
            }
        },
        advancedSettings = {
            useAdvancedConditions = {
                displayName = "Advanced Conditions",
                description = "Use advanced conditions for better decision making",
                type = "toggle",
                default = true
            },
            useMovementAbilities = {
                displayName = "Movement Abilities",
                description = "Use movement abilities when appropriate",
                type = "toggle",
                default = true
            },
            gcdBuffer = {
                displayName = "GCD Buffer",
                description = "Buffer time for GCD checks (seconds)",
                type = "slider",
                min = 0,
                max = 0.2,
                step = 0.01,
                default = 0.1
            },
            actionThrottle = {
                displayName = "Action Throttle",
                description = "Minimum time between actions (seconds)",
                type = "slider",
                min = 0.05,
                max = 0.3,
                step = 0.01,
                default = 0.1
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("RotationManager", function(settings)
        self:ApplySettings(settings)
    end)
}

-- Apply settings
function RotationManager:ApplySettings(settings)
    -- Apply general settings
    isEnabled = settings.generalSettings.enableRotation
    
    -- Convert rotation mode
    local modeString = settings.generalSettings.rotationMode
    if modeString == "Automatic" then
        rotationMode = "automatic"
    elseif modeString == "Semi-Automatic" then
        rotationMode = "semiAutomatic"
    elseif modeString == "One Button" then
        rotationMode = "oneButton"
    else
        rotationMode = "manual"
    end
    
    -- Apply update frequency
    updateFrequency = settings.generalSettings.updateFrequency
    
    -- Apply other settings
    smartTargeting = settings.generalSettings.smartTargeting
    aoeEnabled = settings.combatSettings.aoeEnabled
    aoeDetectionRange = settings.combatSettings.aoeDetectionRange
    smartAoeThreshold = settings.combatSettings.aoeThreshold
    useTrinkets = settings.combatSettings.useTrinkets
    useDefensives = settings.combatSettings.useDefensives
    useInterrupts = settings.combatSettings.useInterrupts
    useCrowdControl = settings.combatSettings.useCrowdControl
    useCooldowns = settings.combatSettings.useCooldowns
    useAuxiliaryAbilities = settings.combatSettings.useAuxiliaryAbilities
    
    -- Apply settings for new features
    local useRacials = settings.combatSettings.useRacials
    local useConsumables = settings.combatSettings.useConsumables
    local useAutoDispel = settings.combatSettings.useAutoDispel
    local useGroupBuffs = settings.combatSettings.useGroupBuffs
    
    -- Pass settings to the new modules
    if ItemManager and ItemManager.UpdateSettings then
        ItemManager.UpdateSettings({
            enableTrinketUsage = useTrinkets,
            enableAutomaticConsumables = useConsumables
        })
    end
    
    if RacialsManager and RacialsManager.UpdateSettings then
        RacialsManager.UpdateSettings({
            enableRacialUsage = useRacials
        })
    end
    
    if BuffManager and BuffManager.UpdateSettings then
        BuffManager.UpdateSettings({
            trackGroupBuffs = useGroupBuffs
        })
    end
    
    if DispelManager and DispelManager.UpdateSettings then
        DispelManager.UpdateSettings({
            enableAutoDispel = useAutoDispel
        })
    end
    
    if PriorityQueue and PriorityQueue.UpdateSettings then
        PriorityQueue.UpdateSettings({
            enablePriorityQueue = true,
            adaptivePriorities = useAdvancedConditions,
            overrideBaseRotation = true
        })
    end
    
    -- Apply advanced settings
    useAdvancedConditions = settings.advancedSettings.useAdvancedConditions
    useMovementAbilities = settings.advancedSettings.useMovementAbilities
    GCD_BUFFER = settings.advancedSettings.gcdBuffer
    ACTION_THROTTLE = settings.advancedSettings.actionThrottle
    
    -- Update frame based on new settings
    if isEnabled then
        rotationFrame:Show()
    else
        rotationFrame:Hide()
    end
    
    API.PrintDebug("Rotation settings applied")
}

-- Create rotation frame
function RotationManager:CreateRotationFrame()
    rotationFrame = CreateFrame("Frame", "WindrunnerRotationsRotationFrame")
    
    -- Set up OnUpdate handler
    rotationFrame:SetScript("OnUpdate", function(self, elapsed)
        RotationManager:OnUpdate(elapsed)
    end)
    
    -- Only show if enabled
    if isEnabled then
        rotationFrame:Show()
    else
        rotationFrame:Hide()
    end
end

-- Register events
function RotationManager:RegisterEvents()
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        RotationManager:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        RotationManager:OnLeaveCombat()
    end)
    
    -- Register for player target changed
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        RotationManager:OnTargetChanged()
    end)
    
    -- Register for unit health changed
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        if unit == "player" or unit == "target" then
            RotationManager:OnUnitHealthChanged(unit)
        end
    end)
    
    -- Register for player specialization changed
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            RotationManager:OnPlayerSpecChanged()
        end
    end)
    
    -- Register for player entering world
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        RotationManager:OnPlayerEnteringWorld()
    end)
}

-- Register built-in rotations
function RotationManager:RegisterBuiltInRotations()
    -- Register a simple testing rotation
    self:RegisterRotation("Testing", {
        id = "testing",
        name = "Testing Rotation",
        class = "ALL",
        spec = 0,
        level = 1,
        description = "A simple testing rotation for development",
        author = "WindrunnerRotations",
        version = "1.0.0",
        rotation = function()
            -- Just a testing rotation
            if UnitExists("target") and UnitCanAttack("player", "target") then
                -- Try to cast a simple spell if available
                local testSpellID = API.GetActiveSpecID() == 1 and 585 or 100 -- Smite for Priests, blank for others
                
                if API.IsSpellKnown(testSpellID) and API.IsSpellUsable(testSpellID) then
                    return {
                        type = actionTypes.SPELL,
                        id = testSpellID,
                        target = "target"
                    }
                end
            end
            
            return nil
        end
    })
}

-- OnUpdate handler
function RotationManager:OnUpdate(elapsed)
    -- Skip if disabled
    if not isEnabled then
        return
    end
    
    -- Update time tracking
    lastUpdate = lastUpdate + elapsed
    
    -- Only update at the specified frequency
    if lastUpdate < updateFrequency then
        return
    end
    
    -- Reset update timer
    lastUpdate = 0
    
    -- Check if we should execute the rotation
    if self:ShouldExecuteRotation() then
        -- Execute rotation
        self:ExecuteRotation()
    end
}

-- Prepare combat state information for all modules
function RotationManager:PrepareCombatState()
    -- Get basic player information
    local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100
    local playerPower = 0
    local powerType = UnitPowerType("player")
    
    -- Determine appropriate power resource based on class/spec
    if powerType == 0 then  -- Mana
        playerPower = UnitPower("player") / UnitPowerMax("player") * 100
    elseif powerType == 1 then  -- Rage
        playerPower = UnitPower("player")
    elseif powerType == 2 then  -- Focus
        playerPower = UnitPower("player")
    elseif powerType == 3 then  -- Energy
        playerPower = UnitPower("player")
    elseif powerType == 4 then  -- Combo Points
        playerPower = UnitPower("player", Enum.PowerType.ComboPoints)
    elseif powerType == 5 then  -- Runes (Death Knight)
        -- Count available runes
        playerPower = 0
        for i = 1, 6 do
            local start, duration, runeReady = GetRuneCooldown(i)
            if runeReady then
                playerPower = playerPower + 1
            end
        end
    elseif powerType == 6 then  -- Runic Power
        playerPower = UnitPower("player")
    elseif powerType == 7 then  -- Soul Shards
        playerPower = UnitPower("player", Enum.PowerType.SoulShards)
    elseif powerType == 8 then  -- Astral Power
        playerPower = UnitPower("player", Enum.PowerType.LunarPower)
    elseif powerType == 9 then  -- Holy Power
        playerPower = UnitPower("player", Enum.PowerType.HolyPower)
    elseif powerType == 10 then  -- Alternate
        -- Classes with alternate power
        local className = select(2, UnitClass("player"))
        if className == "MONK" then
            playerPower = UnitPower("player", Enum.PowerType.Chi)
        elseif className == "WARLOCK" then
            playerPower = UnitPower("player", Enum.PowerType.SoulShards)
        elseif className == "DRUID" then
            playerPower = UnitPower("player", Enum.PowerType.LunarPower)
        elseif className == "EVOKER" then
            playerPower = UnitPower("player", Enum.PowerType.Essence)
        else
            playerPower = UnitPower("player")
        end
    else
        playerPower = UnitPower("player")
    end
    
    -- Get target information
    local targetHealth = 0
    if UnitExists("target") then
        targetHealth = UnitHealth("target") / UnitHealthMax("target") * 100
    end
    
    -- Count number of enemies in combat range
    local enemyCount = API.GetEnemiesInRange("player", aoeDetectionRange)
    
    -- Check if in execute phase
    local isExecutePhase = false
    if UnitExists("target") then
        local executeThreshold = 20  -- Default 20%
        if UnitClassification("target") == "worldboss" or UnitClassification("target") == "rareelite" or UnitClassification("target") == "elite" then
            executeThreshold = 35  -- Higher threshold for boss/elite mobs, warrior-style
        end
        
        isExecutePhase = targetHealth <= executeThreshold
    end
    
    -- Determine if enemy is casting
    local enemyCasting = false
    if UnitExists("target") then
        local spellName, _, _, startTime, endTime = UnitCastingInfo("target")
        if spellName then
            enemyCasting = true
        else
            spellName, _, _, startTime, endTime = UnitChannelInfo("target")
            if spellName then
                enemyCasting = true
            end
        end
    end
    
    -- Determine if we're in a burst window (cooldowns active)
    local burstWindow = false
    if useCooldowns then
        -- Check if we have major cooldowns active
        -- Different per class, simplistic example
        local className = select(2, UnitClass("player"))
        if className == "WARRIOR" and API.HasBuff("player", 1719) then -- Recklessness
            burstWindow = true
        elseif className == "MAGE" and API.HasBuff("player", 12472) then -- Icy Veins
            burstWindow = true
        elseif className == "PALADIN" and API.HasBuff("player", 31884) then -- Avenging Wrath
            burstWindow = true
        elseif className == "PRIEST" and (API.HasBuff("player", 10060) or API.HasBuff("player", 194249)) then -- Power Infusion or Voidform
            burstWindow = true
        elseif className == "WARLOCK" and API.HasBuff("player", 1122) then -- Summon Infernal
            burstWindow = true
        elseif className == "HUNTER" and API.HasBuff("player", 193530) then -- Aspect of the Wild
            burstWindow = true
        elseif className == "DRUID" and API.HasBuff("player", 194223) then -- Celestial Alignment
            burstWindow = true
        elseif className == "DEATHKNIGHT" and API.HasBuff("player", 51271) then -- Pillar of Frost
            burstWindow = true
        end
    end
    
    -- Build the combat state structure
    local combatState = {
        inCombat = inCombat,
        health = playerHealth,
        resource = playerPower,
        targetHealth = targetHealth,
        enemyCount = enemyCount,
        executePhase = isExecutePhase,
        enemyCasting = enemyCasting,
        burstWindow = burstWindow,
        movementRequired = false, -- Would need more complex logic to determine
        spec = GetSpecialization()
    }
    
    return combatState
end

-- Should execute rotation
function RotationManager:ShouldExecuteRotation()
    -- Skip if rotation is paused
    if pauseRotation then
        return false
    end
    
    -- Skip if automatic mode is not enabled
    if rotationMode ~= "automatic" and rotationMode ~= "semiAutomatic" then
        return false
    end
    
    -- Skip if no active rotation
    if not activeRotation then
        return false
    end
    
    -- Skip if GCD is active
    local remainingGCD = API.GetRemainingGCD()
    if remainingGCD > GCD_BUFFER then
        return false
    end
    
    -- Skip if we're already executing
    if adlExecuting then
        return false
    end
    
    -- Skip if we have a spell queued but it's not ready yet
    if nextSpellInfo and nextSpellCooldown > GetTime() then
        return false
    end
    
    -- Skip if we just cast something and action throttle is active
    if lastRotationExecuteTime + ACTION_THROTTLE > GetTime() then
        return false
    end
    
    -- Skip if anti-detection system says to wait
    if AntiDetectionSystem and AntiDetectionSystem.IsInSafeMode and AntiDetectionSystem:IsInSafeMode() then
        return false
    end
    
    return true
end

-- Execute rotation
function RotationManager:ExecuteRotation()
    -- Mark as executing
    adlExecuting = true
    
    -- Measure execution time
    local startTime = debugprofilestop()
    
    -- Prepare combat state for modules
    local combatState = self:PrepareCombatState()
    
    -- Set up error handling with ErrorHandler
    local success = false
    local result = nil
    local priorityAction = nil
    
    -- Check if we have a Priority Queue system available and it's enabled
    local usePriorityQueue = PriorityQueue and PriorityQueue.ProcessQueue
    
    if usePriorityQueue then
        -- Get player class and spec info
        local playerClass = select(2, UnitClass("player"))
        local playerSpec = GetSpecialization()
        
        -- Try to get an action from the priority queue
        priorityAction = PriorityQueue.ProcessQueue(playerClass, playerSpec, combatState)
    end
    
    -- Process automated systems first regardless of rotation
    if not priorityAction then
        -- Try automatic trinket usage if enabled
        if useTrinkets and ItemManager and ItemManager.ProcessTrinkets then
            local trinketResult = ItemManager.ProcessTrinkets(combatState)
            if trinketResult then
                priorityAction = {
                    type = actionTypes.ITEM,
                    id = trinketResult.id,
                    target = trinketResult.target or "player"
                }
            end
        end
        
        -- Try automatic consumable usage if enabled
        if not priorityAction and ConfigRegistry.GetSettings("RotationManager").combatSettings.useConsumables and ItemManager and ItemManager.ProcessConsumables then
            local consumableResult = ItemManager.ProcessConsumables(combatState)
            if consumableResult then
                priorityAction = {
                    type = actionTypes.ITEM,
                    id = consumableResult.id,
                    target = consumableResult.target or "player"
                }
            end
        end
        
        -- Try automatic racial ability usage if enabled
        if not priorityAction and ConfigRegistry.GetSettings("RotationManager").combatSettings.useRacials and RacialsManager and RacialsManager.ProcessRacials then
            local racialResult = RacialsManager.ProcessRacials(combatState)
            if racialResult then
                priorityAction = {
                    type = actionTypes.SPELL,
                    id = racialResult.id,
                    target = racialResult.target or "target"
                }
            end
        end
        
        -- Try automatic dispel if enabled
        if not priorityAction and ConfigRegistry.GetSettings("RotationManager").combatSettings.useAutoDispel and DispelManager and DispelManager.ProcessDispels then
            local dispelResult = DispelManager.ProcessDispels(combatState)
            if dispelResult then
                priorityAction = {
                    type = actionTypes.SPELL,
                    id = dispelResult.id,
                    target = dispelResult.target
                }
            end
        end
        
        -- Try automatic buff management if enabled
        if not priorityAction and ConfigRegistry.GetSettings("RotationManager").combatSettings.useGroupBuffs and BuffManager and BuffManager.ProcessBuffs then
            local buffResult = BuffManager.ProcessBuffs(combatState)
            if buffResult then
                priorityAction = {
                    type = actionTypes.SPELL,
                    id = buffResult.id,
                    target = buffResult.target or "player"
                }
            end
        end
    end
    
    -- If we have a priority action at this point, use it
    if priorityAction then
        success = true
        result = priorityAction
    else
        -- Otherwise fall back to the regular rotation
        if ErrorHandler and ErrorHandler.BeginTransaction then
            -- Use transaction-based execution
            ErrorHandler:BeginTransaction("RotationExecution")
            
            -- Execute rotation function
            success, result = pcall(function()
                return activeRotation.rotation()
            end)
            
            if success then
                ErrorHandler:CommitTransaction()
            else
                ErrorHandler:RollbackTransaction()
                -- Record error
                self:RecordRotationError(result)
            end
        else
            -- Fallback to basic pcall if ErrorHandler is not available
            success, result = pcall(function()
                return activeRotation.rotation()
            end)
            
            if not success then
                -- Record error
                self:RecordRotationError(result)
            end
        end
    end
    
    -- Measure execution time
    local endTime = debugprofilestop()
    rotationExecutionTime = endTime - startTime
    
    -- Update tracking
    rotationTracking.executionCount = rotationTracking.executionCount + 1
    lastRotationExecuteTime = GetTime()
    
    -- Clear executing flag
    adlExecuting = false
    
    -- Process result
    if success and result then
        -- Process the action
        self:ProcessAction(result)
        rotationTracking.successCount = rotationTracking.successCount + 1
    else
        rotationTracking.failCount = rotationTracking.failCount + 1
    end
    
    -- Update performance metrics
    if PerformanceManager and PerformanceManager.GetDetailLevel then
        local detailLevel = PerformanceManager:GetDetailLevel("RotationManager")
        if detailLevel >= 5 then
            API.PrintDebug(string.format("Rotation execution time: %.2f ms", rotationExecutionTime))
        end
    end
}

-- Process action
function RotationManager:ProcessAction(action)
    -- Skip if no action
    if not action then
        return
    end
    
    -- Add to recent actions
    table.insert(recentActions, {
        type = action.type,
        id = action.id,
        target = action.target,
        timestamp = GetTime()
    })
    
    -- Trim recent actions
    while #recentActions > MAX_RECENT_ACTIONS do
        table.remove(recentActions, 1)
    end
    
    -- Process based on action type
    if action.type == actionTypes.SPELL then
        -- Cast spell
        if AntiDetectionSystem and AntiDetectionSystem.QueueFunction then
            -- Use anti-detection system to queue the spell
            AntiDetectionSystem:QueueFunction("CastSpellByID", CastSpellByID, action.id, action.target)
        else
            -- Cast directly
            API.CastSpell(action.id, action.target)
        end
        
        -- Update tracking
        rotationTracking.lastSpell = action.id
        
        -- Record spell execution
        rotationTracking.spellsExecuted[action.id] = (rotationTracking.spellsExecuted[action.id] or 0) + 1
    elseif action.type == actionTypes.ITEM then
        -- Use item
        if AntiDetectionSystem and AntiDetectionSystem.QueueFunction then
            -- Use anti-detection system to queue the item
            AntiDetectionSystem:QueueFunction("UseItemByName", UseItemByName, action.id, action.target)
        else
            -- Use directly
            API.UseItem(action.id, action.target)
        end
    elseif action.type == actionTypes.MACRO then
        -- Run macro
        if AntiDetectionSystem and AntiDetectionSystem.QueueFunction then
            -- Use anti-detection system to queue the macro
            AntiDetectionSystem:QueueFunction("RunMacroText", RunMacroText, action.id)
        else
            -- Run directly
            RunMacroText(action.id)
        end
    elseif action.type == actionTypes.TARGET then
        -- Set target
        if AntiDetectionSystem and AntiDetectionSystem.QueueFunction then
            -- Use anti-detection system to queue the target change
            AntiDetectionSystem:QueueFunction("TargetUnit", TargetUnit, action.id)
        else
            -- Target directly
            TargetUnit(action.id)
        end
    elseif action.type == actionTypes.FOCUS then
        -- Set focus
        if AntiDetectionSystem and AntiDetectionSystem.QueueFunction then
            -- Use anti-detection system to queue the focus change
            AntiDetectionSystem:QueueFunction("FocusUnit", FocusUnit, action.id)
        else
            -- Focus directly
            FocusUnit(action.id)
        end
    elseif action.type == actionTypes.WAIT then
        -- Pause rotation for specified time
        pauseRotation = true
        C_Timer.After(action.id or 0.5, function()
            pauseRotation = false
        end)
    elseif action.type == actionTypes.STOP then
        -- Stop rotation
        self:StopRotation()
    end
}

-- Record rotation error
function RotationManager:RecordRotationError(error)
    -- Save error
    lastRotationError = error
    rotationErrorCount = rotationErrorCount + 1
    
    -- Log error
    API.PrintError("Rotation error: " .. tostring(error))
    
    -- Check if we've hit max errors
    if rotationErrorCount >= maxRotationErrors then
        API.PrintError("Too many rotation errors, stopping rotation")
        self:StopRotation()
    end
}

-- On enter combat
function RotationManager:OnEnterCombat()
    -- Set combat state
    inCombat = true
    
    -- Reset rotation tracking
    rotationTracking.startTime = GetTime()
    rotationTracking.executionCount = 0
    rotationTracking.successCount = 0
    rotationTracking.failCount = 0
    rotationTracking.spellsExecuted = {}
    rotationTracking.lastSpell = nil
    
    -- Reset combat metrics
    combatMetrics.startTime = GetTime()
    combatMetrics.damageDone = 0
    combatMetrics.damageBreakdown = {}
    combatMetrics.successfulCasts = 0
    combatMetrics.failedCasts = 0
    
    -- Update rotation state
    self:UpdateRotationState()
    
    -- Refresh APL
    self:RefreshAPL()
    
    API.PrintDebug("Rotation Manager: Combat started")
}

-- On leave combat
function RotationManager:OnLeaveCombat()
    -- Set combat state
    inCombat = false
    
    -- Update combat metrics
    combatMetrics.endTime = GetTime()
    local combatDuration = combatMetrics.endTime - combatMetrics.startTime
    if combatDuration > 0 then
        combatMetrics.dps = combatMetrics.damageDone / combatDuration
    end
    
    -- Calculate rotation efficiency
    if rotationTracking.executionCount > 0 then
        combatMetrics.rotationEfficiency = rotationTracking.successCount / rotationTracking.executionCount
    end
    
    -- Calculate average execute time
    combatMetrics.averageExecuteTime = rotationExecutionTime
    
    -- Find best and worst actions
    if CombatAnalysis and CombatAnalysis.GetSpellCasts then
        -- Get data from combat analysis
        local spellCasts = CombatAnalysis:GetSpellCasts()
        local damageDone = CombatAnalysis:GetDamageDone()
        
        -- Find best and worst actions
        local bestDPS = 0
        local worstDPS = 999999999
        
        for spellID, data in pairs(damageDone) do
            -- Calculate spell DPS
            local casts = 0
            for _, cast in ipairs(spellCasts) do
                if cast.spellID == spellID then
                    casts = casts + 1
                end
            end
            
            if casts > 0 and combatDuration > 0 then
                local spellDPS = data.total / combatDuration
                
                if spellDPS > bestDPS then
                    bestDPS = spellDPS
                    combatMetrics.bestAction = {
                        id = spellID,
                        name = data.name,
                        dps = spellDPS
                    }
                end
                
                if spellDPS < worstDPS and spellDPS > 0 then
                    worstDPS = spellDPS
                    combatMetrics.worstAction = {
                        id = spellID,
                        name = data.name,
                        dps = spellDPS
                    }
                end
            end
        end
    end
    
    API.PrintDebug("Rotation Manager: Combat ended")
}

-- On target changed
function RotationManager:OnTargetChanged()
    -- Update last target change time
    lastTargetChangeTime = GetTime()
    
    -- Get new target
    if UnitExists("target") then
        lastTarget = "target"
    else
        lastTarget = nil
    end
    
    -- Update rotation state
    self:UpdateRotationState()
    
    -- Reset execute phase if target changes
    executePhase = false
}

-- On unit health changed
function RotationManager:OnUnitHealthChanged(unit)
    -- Update execution phase check for target
    if unit == "target" and UnitExists("target") then
        local healthPct = UnitHealth("target") / UnitHealthMax("target") * 100
        executePhase = healthPct <= 20 -- Assume execute phase at 20% health
        
        -- Update rotation state
        currentRotationState.targetHealth = healthPct
    end
    
    -- Update player health in rotation state
    if unit == "player" then
        local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
        currentRotationState.health = healthPct
    end
}

-- On player spec changed
function RotationManager:OnPlayerSpecChanged()
    -- Get new spec
    local specID = API.GetActiveSpecID()
    
    -- Reset execute phase
    executePhase = false
    
    -- Update rotation state
    currentRotationState.spec = specID
    
    -- Clear rotation cache
    rotationCache = {}
    
    -- Update active rotation
    self:UpdateActiveRotation()
    
    API.PrintDebug("Rotation Manager: Spec changed to " .. specID)
}

-- On player entering world
function RotationManager:OnPlayerEnteringWorld()
    -- Reset states
    inCombat = UnitAffectingCombat("player")
    executePhase = false
    
    -- Clear rotation cache
    rotationCache = {}
    
    -- Update active rotation
    self:UpdateActiveRotation()
    
    -- Update rotation state
    self:UpdateRotationState()
}

-- Update rotation state
function RotationManager:UpdateRotationState()
    -- Get player info
    local playerInfo = API.GetPlayerInfo()
    
    -- Update health percentages
    currentRotationState.health = UnitHealth("player") / UnitHealthMax("player") * 100
    
    if UnitExists("target") then
        currentRotationState.targetHealth = UnitHealth("target") / UnitHealthMax("target") * 100
    else
        currentRotationState.targetHealth = 0
    end
    
    -- Update target count
    currentRotationState.targetCount = API.GetEnemyCount(aoeDetectionRange)
    
    -- Update spec info
    currentRotationState.spec = playerInfo.specID
    
    -- Update execute phase
    currentRotationState.executePhase = executePhase
    
    -- Update resource info (simplified - would be more complex in real implementation)
    local primaryPowerType = UnitPowerType("player")
    currentRotationState.resource = UnitPower("player", primaryPowerType) / UnitPowerMax("player", primaryPowerType) * 100
    
    -- Update buff and debuff list (simplified)
    currentRotationState.buffsActive = {}
    currentRotationState.debuffsActive = {}
    
    -- In a real implementation, this would scan all active buffs and debuffs
}

-- Update active rotation
function RotationManager:UpdateActiveRotation()
    -- Get player info
    local playerInfo = API.GetPlayerInfo()
    
    -- Find appropriate rotation for class and spec
    for _, rotation in pairs(rotations) do
        if (rotation.class == "ALL" or rotation.class == playerInfo.class) and
           (rotation.spec == 0 or rotation.spec == playerInfo.specID) and
           playerInfo.level >= rotation.level then
            -- Found matching rotation
            activeRotation = rotation
            
            API.PrintDebug("Active rotation set to: " .. rotation.name)
            return
        end
    end
    
    -- If no match, use first available rotation that matches class
    for _, rotation in pairs(rotations) do
        if rotation.class == "ALL" or rotation.class == playerInfo.class then
            -- Found class-matching rotation
            activeRotation = rotation
            
            API.PrintDebug("Active rotation set to: " .. rotation.name)
            return
        end
    end
    
    -- If still no match, use testing rotation
    activeRotation = rotations["Testing"]
    
    if activeRotation then
        API.PrintDebug("Active rotation set to testing rotation")
    else
        API.PrintDebug("No suitable rotation found")
    end
}

-- Register rotation
function RotationManager:RegisterRotation(id, rotationData)
    -- Validate rotation
    if not id or not rotationData or not rotationData.rotation then
        API.PrintError("Invalid rotation data")
        return false
    end
    
    -- Store rotation
    rotations[id] = rotationData
    
    API.PrintDebug("Registered rotation: " .. rotationData.name)
    return true
end

-- Unregister rotation
function RotationManager:UnregisterRotation(id)
    -- Remove rotation
    if rotations[id] then
        rotations[id] = nil
        
        -- If this was the active rotation, update active rotation
        if activeRotation and activeRotation.id == id then
            activeRotation = nil
            self:UpdateActiveRotation()
        end
        
        return true
    end
    
    return false
}

-- Refresh APL
function RotationManager:RefreshAPL()
    -- Skip if not time to refresh
    if GetTime() - lastAPLRefresh < APL_REFRESH_INTERVAL then
        return
    end
    
    -- Update refresh time
    lastAPLRefresh = GetTime()
    
    -- In a real implementation, this would build the APL based on current state
    -- For now, just a placeholder
    currentAPL = {}
    
    -- Example APL entries
    if activeRotation then
        currentAPL = {
            name = activeRotation.name,
            class = activeRotation.class,
            spec = activeRotation.spec,
            lastRefresh = GetTime()
        }
    end
}

-- Start rotation
function RotationManager:StartRotation()
    -- Skip if already active
    if rotationActive then
        return
    end
    
    -- Set active
    rotationActive = true
    
    -- Show frame
    rotationFrame:Show()
    
    -- Reset error count
    rotationErrorCount = 0
    
    -- Reset tracking
    rotationTracking = {
        spellsExecuted = {},
        lastSpell = nil,
        startTime = GetTime(),
        executionCount = 0,
        successCount = 0,
        failCount = 0
    }
    
    -- Clear pause
    pauseRotation = false
    
    -- Update active rotation
    self:UpdateActiveRotation()
    
    -- Refresh APL
    self:RefreshAPL()
    
    API.PrintMessage("Rotation started")
}

-- Stop rotation
function RotationManager:StopRotation()
    -- Skip if not active
    if not rotationActive then
        return
    end
    
    -- Set inactive
    rotationActive = false
    
    -- Hide frame if not automatic
    if rotationMode ~= "automatic" then
        rotationFrame:Hide()
    end
    
    API.PrintMessage("Rotation stopped")
}

-- Toggle rotation
function RotationManager:ToggleRotation()
    if rotationActive then
        self:StopRotation()
    else
        self:StartRotation()
    end
    
    return rotationActive
}

-- Register slash commands
function RotationManager:RegisterSlashCommands()
    -- Register /wr command
    SLASH_WINDRUNNERROTATIONS1 = "/wr"
    SlashCmdList["WINDRUNNERROTATIONS"] = function(msg)
        self:HandleSlashCommand(msg)
    end
    
    API.PrintDebug("Registered slash commands")
}

-- Handle slash command
function RotationManager:HandleSlashCommand(msg)
    -- Parse command
    local command, args = strsplit(" ", msg, 2)
    command = strlower(command or "")
    
    -- Process command
    if command == "start" then
        -- Start rotation
        self:StartRotation()
    elseif command == "stop" then
        -- Stop rotation
        self:StopRotation()
    elseif command == "toggle" then
        -- Toggle rotation
        self:ToggleRotation()
    elseif command == "mode" then
        -- Change mode
        if args then
            args = strlower(args)
            if args == "auto" or args == "automatic" then
                rotationMode = "automatic"
            elseif args == "semi" or args == "semiauto" or args == "semiautomatic" then
                rotationMode = "semiAutomatic"
            elseif args == "one" or args == "onebutton" then
                rotationMode = "oneButton"
            elseif args == "manual" then
                rotationMode = "manual"
            end
            
            API.PrintMessage("Rotation mode set to: " .. rotationMode)
        else
            API.PrintMessage("Current rotation mode: " .. rotationMode)
        end
    elseif command == "status" then
        -- Show status
        self:PrintStatus()
    elseif command == "aoe" then
        -- Toggle AoE
        aoeEnabled = not aoeEnabled
        API.PrintMessage("AoE " .. (aoeEnabled and "enabled" : "disabled"))
    elseif command == "cd" or command == "cooldowns" then
        -- Toggle cooldowns
        useCooldowns = not useCooldowns
        API.PrintMessage("Cooldowns " .. (useCooldowns and "enabled" : "disabled"))
    elseif command == "debug" then
        -- Toggle debug mode
        API.EnableDebugMode(not API.IsDebugMode())
    else
        -- Show help
        self:PrintHelp()
    end
end

-- Print status
function RotationManager:PrintStatus()
    -- Print general status
    API.PrintMessage("Rotation status:")
    API.PrintMessage("  Active: " .. (rotationActive and "Yes" : "No"))
    API.PrintMessage("  Mode: " .. rotationMode)
    
    -- Print active rotation
    if activeRotation then
        API.PrintMessage("  Current rotation: " .. activeRotation.name)
    else
        API.PrintMessage("  Current rotation: None")
    end
    
    -- Print combat stats
    API.PrintMessage("  In combat: " .. (inCombat and "Yes" : "No"))
    API.PrintMessage("  Execute phase: " .. (executePhase and "Yes" : "No"))
    
    -- Print tracking stats
    if rotationTracking.startTime > 0 then
        local uptime = GetTime() - rotationTracking.startTime
        API.PrintMessage(string.format("  Runtime: %.1f seconds", uptime))
        API.PrintMessage(string.format("  Executions: %d (%.1f%% success rate)", 
                        rotationTracking.executionCount,
                        rotationTracking.executionCount > 0 and (rotationTracking.successCount / rotationTracking.executionCount * 100) or 0))
    end
    
    -- Print settings
    API.PrintMessage("  AoE: " .. (aoeEnabled and "Enabled" : "Disabled"))
    API.PrintMessage("  Cooldowns: " .. (useCooldowns and "Enabled" : "Disabled"))
    API.PrintMessage("  Defensives: " .. (useDefensives and "Enabled" : "Disabled"))
    API.PrintMessage("  Interrupts: " .. (useInterrupts and "Enabled" : "Disabled"))
}

-- Print help
function RotationManager:PrintHelp()
    API.PrintMessage("WindrunnerRotations commands:")
    API.PrintMessage("  /wr start - Start rotation")
    API.PrintMessage("  /wr stop - Stop rotation")
    API.PrintMessage("  /wr toggle - Toggle rotation")
    API.PrintMessage("  /wr mode [auto|semi|one|manual] - Set or show rotation mode")
    API.PrintMessage("  /wr status - Show rotation status")
    API.PrintMessage("  /wr aoe - Toggle AoE abilities")
    API.PrintMessage("  /wr cooldowns - Toggle cooldown usage")
    API.PrintMessage("  /wr debug - Toggle debug mode")
}

-- Get active rotation
function RotationManager:GetActiveRotation()
    return activeRotation
end

-- Is rotation active
function RotationManager:IsRotationActive()
    return rotationActive
end

-- Get rotation mode
function RotationManager:GetRotationMode()
    return rotationMode
end

-- Set rotation mode
function RotationManager:SetRotationMode(mode)
    if mode == "automatic" or mode == "semiAutomatic" or mode == "oneButton" or mode == "manual" then
        rotationMode = mode
        return true
    end
    
    return false
}

-- Get combat metrics
function RotationManager:GetCombatMetrics()
    return combatMetrics
end

-- Get rotation tracking
function RotationManager:GetRotationTracking()
    return rotationTracking
end

-- Get rotation state
function RotationManager:GetRotationState()
    return currentRotationState
end

-- Get all rotations
function RotationManager:GetAllRotations()
    return rotations
end

-- Is in execute phase
function RotationManager:IsInExecutePhase()
    return executePhase
end

-- Is enabled
function RotationManager:IsEnabled()
    return isEnabled
end

-- Reset
function RotationManager:Reset()
    -- Stop rotation
    self:StopRotation()
    
    -- Reset rotation cache
    rotationCache = {}
    
    -- Clear error count
    rotationErrorCount = 0
    
    -- Update active rotation
    self:UpdateActiveRotation()
    
    -- Update rotation state
    self:UpdateRotationState()
    
    -- Refresh APL
    self:RefreshAPL()
    
    return true
end

-- Register for export
WR.RotationManager = RotationManager

return RotationManager