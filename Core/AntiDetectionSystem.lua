------------------------------------------
-- WindrunnerRotations - Anti-Detection System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local AntiDetectionSystem = {}
WR.AntiDetectionSystem = AntiDetectionSystem

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local PerformanceManager = WR.PerformanceManager

-- Anti-detection data
local isEnabled = true
local actionExecutor = nil
local actionQueue = {}
local actionHistory = {}
local actionPatterns = {}
local lastActionTime = 0
local humanizedDelay = 0
local MIN_DELAY = 0.05
local MAX_DELAY = 0.25
local MAX_HISTORY_SIZE = 100
local detectionLevel = 0 -- 0 = safe, 10 = high risk
local wardenCheckDetected = false
local wardenCheckLastTime = 0
local lastRandomization = 0
local RANDOMIZATION_INTERVAL = 60 -- Seconds between pattern randomization
local jitterFactor = 0.2 -- 20% random jitter in delays
local obfuscatedNames = {}
local MAX_QUEUE_SIZE = 50
local maxQueueTime = 1.0 -- Max seconds between queue processes
local lastQueueProcess = 0
local actionTypeThrottles = {}
local throttleResetInterval = 5.0 -- Seconds between throttle resets
local lastThrottleReset = 0
local actionTypeCounters = {}
local consecutiveActionThreshold = 5 -- Max number of same action type in a row
local actionDistribution = {}
local functionsToProtect = {
    "CastSpellByName",
    "CastSpellByID",
    "UseItemByName",
    "UseContainerItem",
    "RunMacroText",
    "TargetUnit",
    "ClearTarget",
    "SpellStopCasting",
    "SpellStopTargeting",
    "PetAttack",
    "AssistUnit",
    "FocusUnit"
}
local functionHooks = {}
local patternsToAvoid = {}
local safetyThresholds = {
    sequenceDetection = 0.7, -- 70% similar sequence triggers alert
    timingDetection = 0.8,   -- 80% identical timing triggers alert
    actionBurst = 10,        -- More than 10 actions per second is risky
    actionGap = 5.0          -- No actions for 5 seconds is suspicious
}
local safeModeEnabled = false
local safeModeReason = nil
local safetyCheckInterval = 10.0 -- Check safety metrics every 10 seconds
local lastSafetyCheck = 0

-- Initialize the Anti-Detection System
function AntiDetectionSystem:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create action executor frame
    self:CreateActionExecutor()
    
    -- Set up function hooks
    self:SetupFunctionHooks()
    
    -- Initialize anti-detection patterns
    self:InitializeAntiDetectionPatterns()
    
    -- Register events
    self:RegisterEvents()
    
    API.PrintDebug("Anti-Detection System initialized")
    return true
end

-- Register settings
function AntiDetectionSystem:RegisterSettings()
    ConfigRegistry:RegisterSettings("AntiDetectionSystem", {
        generalSettings = {
            enableAntiDetection = {
                displayName = "Enable Anti-Detection",
                description = "Reduce risk of automated behavior detection",
                type = "toggle",
                default = true
            },
            detectionLevel = {
                displayName = "Detection Level",
                description = "Level of anti-detection measures to use",
                type = "dropdown",
                options = {"Minimal", "Standard", "Enhanced", "Paranoid"},
                default = "Standard"
            },
            humanizedDelayMin = {
                displayName = "Minimum Action Delay",
                description = "Minimum delay between actions (seconds)",
                type = "slider",
                min = 0.05,
                max = 0.5,
                step = 0.01,
                default = 0.05
            },
            humanizedDelayMax = {
                displayName = "Maximum Action Delay",
                description = "Maximum delay between actions (seconds)",
                type = "slider",
                min = 0.1,
                max = 1.0,
                step = 0.05,
                default = 0.25
            }
        },
        advancedSettings = {
            jitterFactor = {
                displayName = "Timing Jitter",
                description = "Random variation in action timing (percentage)",
                type = "slider",
                min = 5,
                max = 50,
                step = 5,
                default = 20
            },
            actionPatternRandomization = {
                displayName = "Action Pattern Randomization",
                description = "Randomize action patterns to avoid detection",
                type = "toggle",
                default = true
            },
            randomizationInterval = {
                displayName = "Randomization Interval",
                description = "How often to randomize patterns (seconds)",
                type = "slider",
                min = 30,
                max = 300,
                step = 30,
                default = 60
            },
            adaptiveThrottling = {
                displayName = "Adaptive Throttling",
                description = "Dynamically adjust action rate based on risk factors",
                type = "toggle",
                default = true
            },
            namespaceObfuscation = {
                displayName = "Namespace Obfuscation",
                description = "Obfuscate addon function names",
                type = "toggle",
                default = false
            }
        },
        safetySettings = {
            safeMode = {
                displayName = "Safe Mode",
                description = "Automatically enable safe mode if suspicious activity is detected",
                type = "toggle",
                default = true
            },
            disableOnWardenCheck = {
                displayName = "Disable on Warden Check",
                description = "Temporarily disable when Warden check is detected",
                type = "toggle",
                default = true
            },
            sequenceDetectionThreshold = {
                displayName = "Sequence Detection Threshold",
                description = "Threshold for detecting repeating action sequences",
                type = "slider",
                min = 50,
                max = 90,
                step = 5,
                default = 70
            },
            timingDetectionThreshold = {
                displayName = "Timing Detection Threshold",
                description = "Threshold for detecting similar action timing",
                type = "slider",
                min = 60,
                max = 95,
                step = 5,
                default = 80
            }
        }
    })
}

-- Create action executor
function AntiDetectionSystem:CreateActionExecutor()
    actionExecutor = CreateFrame("Frame", "WindrunnerRotationsActionExecutor")
    actionExecutor:SetScript("OnUpdate", function(self, elapsed)
        AntiDetectionSystem:OnUpdate(elapsed)
    end)
end

-- Register events
function AntiDetectionSystem:RegisterEvents()
    -- Register for addon loaded to apply settings
    API.RegisterEvent("ADDON_LOADED", function(loadedAddonName)
        if loadedAddonName == "WindrunnerRotations" then
            AntiDetectionSystem:ApplySettings()
        end
    end)
    
    -- Register for player entering world to reset detection state
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        AntiDetectionSystem:ResetDetectionState()
    end)
    
    -- Register for zone changes to adjust settings
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        AntiDetectionSystem:AdjustSettingsForZone()
    end)
    
    -- Register for combat state changes
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        AntiDetectionSystem:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        AntiDetectionSystem:OnLeaveCombat()
    end)
}

-- Setup function hooks
function AntiDetectionSystem:SetupFunctionHooks()
    -- Save original functions and replace with our own versions
    for _, funcName in ipairs(functionsToProtect) do
        if _G[funcName] then
            -- Save original function
            functionHooks[funcName] = _G[funcName]
            
            -- Replace with our protected version
            _G[funcName] = function(...)
                return AntiDetectionSystem:QueueFunction(funcName, functionHooks[funcName], ...)
            end
        end
    end
}

-- Initialize anti-detection patterns
function AntiDetectionSystem:InitializeAntiDetectionPatterns()
    -- Initialize action patterns to avoid
    patternsToAvoid = {
        -- Repeating exact same action
        sameAction = {
            pattern = {
                check = function(history)
                    -- Check last 5 actions for exact same action
                    if #history < 5 then return false end
                    
                    local lastAction = history[#history]
                    local sameCount = 0
                    
                    for i = #history-1, #history-4, -1 do
                        if history[i].type == lastAction.type and
                           history[i].target == lastAction.target and
                           history[i].spellID == lastAction.spellID then
                            sameCount = sameCount + 1
                        end
                    end
                    
                    return sameCount >= 3
                end,
                weight = 0.7
            }
        },
        
        -- Perfect timing between actions
        perfectTiming = {
            pattern = {
                check = function(history)
                    -- Check for consistent timing between actions
                    if #history < 10 then return false end
                    
                    local intervals = {}
                    for i = #history, #history-8, -1 do
                        table.insert(intervals, history[i].time - history[i-1].time)
                    end
                    
                    local avgInterval = 0
                    for _, interval in ipairs(intervals) do
                        avgInterval = avgInterval + interval
                    end
                    avgInterval = avgInterval / #intervals
                    
                    -- Calculate standard deviation
                    local variance = 0
                    for _, interval in ipairs(intervals) do
                        variance = variance + (interval - avgInterval)^2
                    end
                    variance = variance / #intervals
                    local stdDev = math.sqrt(variance)
                    
                    -- If standard deviation is very low, timing is too consistent
                    return stdDev < 0.01
                end,
                weight = 0.8
            }
        },
        
        -- Rapid action bursts
        actionBurst = {
            pattern = {
                check = function(history)
                    -- Check for too many actions in a short time
                    if #history < 5 then return false end
                    
                    local now = GetTime()
                    local recentActions = 0
                    
                    for i = #history, 1, -1 do
                        if now - history[i].time < 1.0 then
                            recentActions = recentActions + 1
                        else
                            break
                        end
                    end
                    
                    return recentActions > safetyThresholds.actionBurst
                end,
                weight = 0.9
            }
        },
        
        -- Long action gaps followed by bursts
        actionGap = {
            pattern = {
                check = function(history)
                    -- Check for long gaps followed by bursts
                    if #history < 10 then return false end
                    
                    local now = GetTime()
                    local lastActionTime = history[#history].time
                    
                    -- Check if there was a long gap
                    if now - lastActionTime > safetyThresholds.actionGap then
                        -- Check if there was a burst before the gap
                        local burstActions = 0
                        local burstWindow = 1.0
                        
                        for i = #history-1, #history-5, -1 do
                            if lastActionTime - history[i].time < burstWindow then
                                burstActions = burstActions + 1
                            else
                                break
                            end
                        end
                        
                        return burstActions >= 4
                    end
                    
                    return false
                end,
                weight = 0.6
            }
        },
        
        -- Too predictable targeting pattern
        predictableTargeting = {
            pattern = {
                check = function(history)
                    -- Check for predictable target switching
                    if #history < 10 then return false end
                    
                    local targetPattern = {}
                    for i = #history-9, #history, 1 do
                        if history[i].target then
                            table.insert(targetPattern, history[i].target)
                        end
                    end
                    
                    -- Check for repeating patterns (A-B-A-B or A-B-C-A-B-C)
                    local patternDetected = false
                    
                    -- Check for A-B-A-B pattern
                    if #targetPattern >= 4 then
                        if targetPattern[1] == targetPattern[3] and
                           targetPattern[2] == targetPattern[4] then
                            patternDetected = true
                        end
                    end
                    
                    -- Check for A-B-C-A-B-C pattern
                    if #targetPattern >= 6 then
                        if targetPattern[1] == targetPattern[4] and
                           targetPattern[2] == targetPattern[5] and
                           targetPattern[3] == targetPattern[6] then
                            patternDetected = true
                        end
                    end
                    
                    return patternDetected
                end,
                weight = 0.6
            }
        }
    }
}

-- Apply settings
function AntiDetectionSystem:ApplySettings()
    local settings = ConfigRegistry:GetSettings("AntiDetectionSystem")
    
    -- Apply general settings
    isEnabled = settings.generalSettings.enableAntiDetection
    
    -- Set detection level
    local level = settings.generalSettings.detectionLevel
    if level == "Minimal" then
        detectionLevel = 2
    elseif level == "Standard" then
        detectionLevel = 5
    elseif level == "Enhanced" then
        detectionLevel = 8
    elseif level == "Paranoid" then
        detectionLevel = 10
    end
    
    -- Set delay ranges
    MIN_DELAY = settings.generalSettings.humanizedDelayMin
    MAX_DELAY = settings.generalSettings.humanizedDelayMax
    
    -- Apply advanced settings
    jitterFactor = settings.advancedSettings.jitterFactor / 100
    RANDOMIZATION_INTERVAL = settings.advancedSettings.randomizationInterval
    
    -- Apply safety thresholds
    safetyThresholds.sequenceDetection = settings.safetySettings.sequenceDetectionThreshold / 100
    safetyThresholds.timingDetection = settings.safetySettings.timingDetectionThreshold / 100
}

-- OnUpdate handler
function AntiDetectionSystem:OnUpdate(elapsed)
    -- Skip if disabled
    if not isEnabled then
        return
    end
    
    -- Get current time
    local now = GetTime()
    
    -- Process action queue
    self:ProcessActionQueue(now)
    
    -- Reset throttles periodically
    if now - lastThrottleReset > throttleResetInterval then
        self:ResetActionThrottles()
        lastThrottleReset = now
    end
    
    -- Check for detection patterns
    if now - lastSafetyCheck > safetyCheckInterval then
        self:CheckSafetyMetrics()
        lastSafetyCheck = now
    end
    
    -- Randomize action patterns periodically
    if now - lastRandomization > RANDOMIZATION_INTERVAL then
        self:RandomizeActionPatterns()
        lastRandomization = now
    end
}

-- Process action queue
function AntiDetectionSystem:ProcessActionQueue(now)
    -- Skip if queue is empty
    if #actionQueue == 0 then
        return
    end
    
    -- Skip if not enough time has passed since last action
    if now - lastActionTime < humanizedDelay then
        return
    end
    
    -- Process oldest action in queue
    local action = table.remove(actionQueue, 1)
    
    -- Execute the action
    local success, result = pcall(function()
        if action.args then
            return action.func(unpack(action.args))
        else
            return action.func()
        end
    end)
    
    -- Record action
    self:RecordAction(action, success)
    
    -- Update timing
    lastActionTime = now
    
    -- Set next action delay with humanization
    humanizedDelay = self:GetHumanizedDelay(action.type)
}

-- Queue function
function AntiDetectionSystem:QueueFunction(funcName, originalFunc, ...)
    local args = {...}  -- Store arguments to pass them later
    
    -- Skip queue if anti-detection is disabled or in safe mode
    if not isEnabled or safeModeEnabled then
        -- Try to use Tinkr.Secure.Call if available for protected functions
        if API and API.IsTinkrLoaded and API.IsTinkrLoaded() and 
           Tinkr and Tinkr.Secure and Tinkr.Secure.Call and 
           type(funcName) == "string" then
            return Tinkr.Secure.Call(funcName, unpack(args))
        else
            -- Fallback to original function
            return originalFunc(unpack(args))
        end
    end
    
    -- Skip queue if the queue is too large (safety feature)
    if #actionQueue >= MAX_QUEUE_SIZE then
        -- Execute directly to prevent queue overflow
        API.PrintDebug("Action queue overflow, executing directly: " .. funcName)
        
        -- Try to use Tinkr.Secure.Call if available for protected functions
        if API and API.IsTinkrLoaded and API.IsTinkrLoaded() and 
           Tinkr and Tinkr.Secure and Tinkr.Secure.Call and 
           type(funcName) == "string" then
            return Tinkr.Secure.Call(funcName, unpack(args))
        else
            -- Fallback to original function
            return originalFunc(unpack(args))
        end
    end
    
    -- Determine action type
    local actionType = self:DetermineActionType(funcName, ...)
    
    -- Check if this action type is being throttled
    if self:ShouldThrottleActionType(actionType) then
        -- Skip this action
        API.PrintDebug("Throttling action of type: " .. actionType)
        return nil
    end
    
    -- Prepare arguments
    local args = {...}
    
    -- Add to queue
    table.insert(actionQueue, {
        func = originalFunc,
        args = args,
        funcName = funcName,
        type = actionType,
        time = GetTime(),
        target = self:ExtractTargetFromArgs(funcName, args)
    })
    
    -- Track action type count
    actionTypeCounters[actionType] = (actionTypeCounters[actionType] or 0) + 1
    
    -- Check for consecutive actions of the same type
    if actionTypeCounters[actionType] > consecutiveActionThreshold then
        -- Throttle this action type
        self:ThrottleActionType(actionType)
    end
    
    return true
}

-- Determine action type
function AntiDetectionSystem:DetermineActionType(funcName, ...)
    if funcName == "CastSpellByName" or funcName == "CastSpellByID" then
        local spellID = ...
        if self:IsControlAbility(spellID) then
            return "control"
        elseif self:IsDefensiveAbility(spellID) then
            return "defensive"
        elseif self:IsOffensiveAbility(spellID) then
            return "offensive"
        else
            return "spell"
        end
    elseif funcName == "UseItemByName" or funcName == "UseContainerItem" then
        return "item"
    elseif funcName == "TargetUnit" or funcName == "AssistUnit" or funcName == "FocusUnit" then
        return "targeting"
    elseif funcName == "PetAttack" then
        return "pet"
    elseif funcName == "RunMacroText" then
        return "macro"
    else
        return "other"
    end
end

-- Extract target from args
function AntiDetectionSystem:ExtractTargetFromArgs(funcName, args)
    if funcName == "TargetUnit" or funcName == "AssistUnit" or funcName == "FocusUnit" then
        return args[1]
    elseif funcName == "CastSpellByName" or funcName == "CastSpellByID" then
        if #args >= 2 then
            return args[2]
        end
    end
    
    -- Default to current target if targeting a spell
    if funcName == "CastSpellByName" or funcName == "CastSpellByID" then
        if UnitExists("target") then
            return UnitGUID("target")
        end
    end
    
    return nil
end

-- Is control ability
function AntiDetectionSystem:IsControlAbility(spellID)
    -- This is a simplified implementation
    -- A real implementation would check a comprehensive list
    local controlSpells = {
        -- General crowd control spells
        [118] = true,    -- Polymorph
        [853] = true,    -- Hammer of Justice
        [605] = true,    -- Mind Control
        [2094] = true,   -- Blind
        [5782] = true,   -- Fear
        [6770] = true,   -- Sap
        [3355] = true,   -- Freezing Trap
        [51514] = true,  -- Hex
        [5211] = true,   -- Mighty Bash
        [339] = true,    -- Entangling Roots
        [2637] = true,   -- Hibernate
        [20066] = true,  -- Repentance
        [82691] = true,  -- Ring of Frost
        [115078] = true, -- Paralysis
        [8122] = true,   -- Psychic Scream
        [5246] = true,   -- Intimidating Shout
        [5484] = true,   -- Howl of Terror
        [19386] = true,  -- Wyvern Sting
        [113724] = true, -- Ring of Peace
        [31661] = true,  -- Dragon's Breath
        [33786] = true,  -- Cyclone
        [119381] = true, -- Leg Sweep
        [179057] = true, -- Chaos Nova
        [221562] = true, -- Asphyxiate
        [6789] = true,   -- Mortal Coil
        [317009] = true, -- Sinful Brand
        [255941] = true, -- Wake of Ashes
        [202137] = true, -- Sigil of Silence
        [226943] = true, -- Mind Bomb
    }
    
    return controlSpells[spellID] or false
end

-- Is defensive ability
function AntiDetectionSystem:IsDefensiveAbility(spellID)
    -- This is a simplified implementation
    -- A real implementation would check a comprehensive list
    local defensiveSpells = {
        -- Common defensive cooldowns
        [45438] = true,  -- Ice Block
        [642] = true,    -- Divine Shield
        [871] = true,    -- Shield Wall
        [48792] = true,  -- Icebound Fortitude
        [33206] = true,  -- Pain Suppression
        [22812] = true,  -- Barkskin
        [61336] = true,  -- Survival Instincts
        [31224] = true,  -- Cloak of Shadows
        [186265] = true, -- Aspect of the Turtle
        [198589] = true, -- Blur
        [104773] = true, -- Unending Resolve
        [118038] = true, -- Die by the Sword
        [184364] = true, -- Enraged Regeneration
        [115203] = true, -- Fortifying Brew
        [116849] = true, -- Life Cocoon
        [108271] = true, -- Astral Shift
        [55233] = true,  -- Vampiric Blood
        [1022] = true,   -- Blessing of Protection
        [6940] = true,   -- Blessing of Sacrifice
        [102342] = true, -- Ironbark
        [47788] = true,  -- Guardian Spirit
        [243435] = true, -- Fortifying Brew (Monk tank)
        [198760] = true, -- Intercept
        [122278] = true, -- Dampen Harm
        [122783] = true, -- Diffuse Magic
        [213610] = true, -- Holy Ward
        [235313] = true, -- Blazing Barrier
        [48707] = true,  -- Anti-Magic Shell
        [196555] = true, -- Netherwalk
        [104773] = true, -- Unending Resolve
        [205604] = true, -- Reverse Magic
    }
    
    return defensiveSpells[spellID] or false
end

-- Is offensive ability
function AntiDetectionSystem:IsOffensiveAbility(spellID)
    -- This is a simplified implementation
    -- A real implementation would check a comprehensive list
    local offensiveSpells = {
        -- Common offensive cooldowns
        [12472] = true,  -- Icy Veins
        [190319] = true, -- Combustion
        [1719] = true,   -- Recklessness
        [31884] = true,  -- Avenging Wrath
        [194223] = true, -- Celestial Alignment
        [13750] = true,  -- Adrenaline Rush
        [121471] = true, -- Shadow Blades
        [51271] = true,  -- Pillar of Frost
        [47568] = true,  -- Empower Rune Weapon
        [193530] = true, -- Aspect of the Wild
        [19574] = true,  -- Bestial Wrath
        [12042] = true,  -- Arcane Power
        [191427] = true, -- Metamorphosis
        [275699] = true, -- Apocalypse
        [107574] = true, -- Avatar
        [102560] = true, -- Incarnation: Chosen of Elune
        [113860] = true, -- Dark Soul: Misery
        [113858] = true, -- Dark Soul: Instability
        [152173] = true, -- Serenity
        [137639] = true, -- Storm, Earth, and Fire
        [114050] = true, -- Ascendance (Elemental)
        [114051] = true, -- Ascendance (Enhancement)
        [102543] = true, -- Incarnation: King of the Jungle
        [1966] = true,   -- Feint
        [102342] = true, -- Ironbark
        [5217] = true,   -- Tiger's Fury
        [1856] = true,   -- Vanish
        [162264] = true, -- Metamorphosis (Havoc)
        [106951] = true, -- Berserk
        [188501] = true, -- Spectral Sight
        [2649] = true,   -- Growl
        [205180] = true, -- Summon Darkglare
    }
    
    return offensiveSpells[spellID] or false
end

-- Get humanized delay
function AntiDetectionSystem:GetHumanizedDelay(actionType)
    -- Base delay range
    local minDelay = MIN_DELAY
    local maxDelay = MAX_DELAY
    
    -- Adjust delay based on action type
    if actionType == "targeting" then
        -- Targeting is usually quicker
        minDelay = minDelay * 0.7
        maxDelay = maxDelay * 0.7
    elseif actionType == "defensive" then
        -- Defensive actions should be quicker
        minDelay = minDelay * 0.6
        maxDelay = maxDelay * 0.6
    elseif actionType == "control" then
        -- Control abilities need to be precise
        minDelay = minDelay * 0.8
        maxDelay = maxDelay * 0.8
    end
    
    -- Adjust based on detection level
    local detectionFactor = detectionLevel / 10
    minDelay = minDelay * (1 + detectionFactor * 0.5)
    maxDelay = maxDelay * (1 + detectionFactor * 0.5)
    
    -- Apply random jitter
    local jitter = (math.random() * 2 - 1) * jitterFactor
    
    -- Calculate final delay
    local baseDelay = minDelay + math.random() * (maxDelay - minDelay)
    local finalDelay = baseDelay * (1 + jitter)
    
    -- Ensure delay is within reasonable bounds
    finalDelay = math.max(MIN_DELAY, math.min(finalDelay, MAX_DELAY * 1.5))
    
    return finalDelay
end

-- Record action
function AntiDetectionSystem:RecordAction(action, success)
    -- Create record
    local record = {
        type = action.type,
        funcName = action.funcName,
        time = GetTime(),
        target = action.target,
        success = success,
        delay = humanizedDelay,
        spellID = action.args and action.args[1] or nil
    }
    
    -- Add to history
    table.insert(actionHistory, record)
    
    -- Trim history if needed
    while #actionHistory > MAX_HISTORY_SIZE do
        table.remove(actionHistory, 1)
    end
    
    -- Update action distribution
    actionDistribution[action.type] = (actionDistribution[action.type] or 0) + 1
}

-- Reset action throttles
function AntiDetectionSystem:ResetActionThrottles()
    -- Reset all throttles
    actionTypeThrottles = {}
    
    -- Reset counters
    actionTypeCounters = {}
}

-- Should throttle action type
function AntiDetectionSystem:ShouldThrottleActionType(actionType)
    -- Check if this action type is being throttled
    if actionTypeThrottles[actionType] then
        -- Check if throttle has expired
        if GetTime() - actionTypeThrottles[actionType].startTime > actionTypeThrottles[actionType].duration then
            -- Throttle expired
            actionTypeThrottles[actionType] = nil
            return false
        else
            -- Still throttled
            return true
        end
    end
    
    return false
end

-- Throttle action type
function AntiDetectionSystem:ThrottleActionType(actionType)
    -- Set throttle
    actionTypeThrottles[actionType] = {
        startTime = GetTime(),
        duration = 2.0 + math.random() * 2.0 -- 2-4 second throttle
    }
    
    -- Reset counter
    actionTypeCounters[actionType] = 0
    
    API.PrintDebug("Throttling action type: " .. actionType)
}

-- Check safety metrics
function AntiDetectionSystem:CheckSafetyMetrics()
    local settings = ConfigRegistry:GetSettings("AntiDetectionSystem")
    
    -- Skip if safe mode is disabled
    if not settings.safetySettings.safeMode then
        return
    end
    
    -- Calculate risk score
    local riskScore = 0
    
    -- Check action patterns
    for name, pattern in pairs(patternsToAvoid) do
        if pattern.pattern.check(actionHistory) then
            riskScore = riskScore + pattern.pattern.weight
            
            -- Debug output
            API.PrintDebug("Detected risky pattern: " .. name)
        end
    end
    
    -- Check Warden detection
    if wardenCheckDetected and settings.safetySettings.disableOnWardenCheck then
        riskScore = riskScore + 1.0
        
        -- Debug output
        API.PrintDebug("Detected possible Warden check")
    end
    
    -- Update detection level based on risk score
    detectionLevel = math.min(10, math.max(0, detectionLevel + riskScore * 2))
    
    -- Check if we should enter safe mode
    if riskScore >= 1.5 and not safeModeEnabled then
        self:EnterSafeMode("Suspicious activity detected")
    elseif riskScore < 0.5 and safeModeEnabled then
        -- Exit safe mode if risk is low
        self:ExitSafeMode()
    end
}

-- Randomize action patterns
function AntiDetectionSystem:RandomizeActionPatterns()
    local settings = ConfigRegistry:GetSettings("AntiDetectionSystem")
    
    -- Skip if randomization is disabled
    if not settings.advancedSettings.actionPatternRandomization then
        return
    end
    
    -- Randomize delay ranges
    local baseMin = settings.generalSettings.humanizedDelayMin
    local baseMax = settings.generalSettings.humanizedDelayMax
    
    -- Add 5-20% random variation
    local minAdjust = 1.0 + (math.random() * 0.15) * (math.random() > 0.5 and 1 or -1)
    local maxAdjust = 1.0 + (math.random() * 0.20) * (math.random() > 0.5 and 1 or -1)
    
    MIN_DELAY = baseMin * minAdjust
    MAX_DELAY = baseMax * maxAdjust
    
    -- Ensure min doesn't exceed max
    MIN_DELAY = math.min(MIN_DELAY, MAX_DELAY - 0.05)
    
    -- Randomize jitter
    jitterFactor = settings.advancedSettings.jitterFactor / 100 * (0.8 + math.random() * 0.4)
    
    -- Randomize queue processing
    maxQueueTime = 0.8 + math.random() * 0.4
    
    -- Reset action counters
    actionTypeCounters = {}
    
    -- Log randomization
    API.PrintDebug(string.format("Randomized action patterns: Delay %.2f-%.2f, Jitter %.0f%%", 
                   MIN_DELAY, MAX_DELAY, jitterFactor * 100))
    
    -- Update last randomization time
    lastRandomization = GetTime()
}

-- On enter combat
function AntiDetectionSystem:OnEnterCombat()
    -- Adjust settings for combat
    local inCombatJitter = jitterFactor * 0.8 -- Reduce jitter in combat for better responsiveness
    jitterFactor = inCombatJitter
    
    -- Slightly reduce delays in combat
    MIN_DELAY = MIN_DELAY * 0.9
    MAX_DELAY = MAX_DELAY * 0.9
}

-- On leave combat
function AntiDetectionSystem:OnLeaveCombat()
    -- Restore pre-combat settings
    local settings = ConfigRegistry:GetSettings("AntiDetectionSystem")
    jitterFactor = settings.advancedSettings.jitterFactor / 100
    
    -- Restore default delays
    MIN_DELAY = settings.generalSettings.humanizedDelayMin
    MAX_DELAY = settings.generalSettings.humanizedDelayMax
    
    -- Clear action queue
    actionQueue = {}
}

-- Adjust settings for zone
function AntiDetectionSystem:AdjustSettingsForZone()
    -- Get current zone info
    local _, zoneType = IsInInstance()
    
    -- Adjust settings based on zone type
    if zoneType == "arena" or zoneType == "pvp" then
        -- PvP environments - increase detection measures
        detectionLevel = math.min(10, detectionLevel + 2)
        
        -- Increase delays slightly in PvP to reduce risk
        MIN_DELAY = MIN_DELAY * 1.1
        MAX_DELAY = MAX_DELAY * 1.1
    elseif zoneType == "party" or zoneType == "raid" then
        -- PvE instances - standard detection measures
        detectionLevel = math.max(1, detectionLevel - 1)
    else
        -- Open world - relaxed measures
        detectionLevel = math.max(0, detectionLevel - 2)
    end
}

-- Reset detection state
function AntiDetectionSystem:ResetDetectionState()
    -- Reset detection variables
    wardenCheckDetected = false
    detectionLevel = 5 -- Default to medium
    
    -- Clear history
    actionHistory = {}
    
    -- Reset throttles
    self:ResetActionThrottles()
    
    -- Load settings
    self:ApplySettings()
    
    -- Reset safe mode
    if safeModeEnabled then
        self:ExitSafeMode()
    end
}

-- Enter safe mode
function AntiDetectionSystem:EnterSafeMode(reason)
    -- Skip if already in safe mode
    if safeModeEnabled then
        return
    end
    
    API.PrintMessage("Entering safe mode: " .. reason)
    
    -- Set safe mode
    safeModeEnabled = true
    safeModeReason = reason
    
    -- Clear action queue
    actionQueue = {}
    
    -- Return control to player
    for _, funcName in ipairs(functionsToProtect) do
        if _G[funcName] and functionHooks[funcName] then
            -- Restore original function
            _G[funcName] = functionHooks[funcName]
        end
    end
}

-- Exit safe mode
function AntiDetectionSystem:ExitSafeMode()
    -- Skip if not in safe mode
    if not safeModeEnabled then
        return
    end
    
    API.PrintMessage("Exiting safe mode")
    
    -- Clear safe mode
    safeModeEnabled = false
    safeModeReason = nil
    
    -- Restore function hooks
    self:SetupFunctionHooks()
}

-- Toggle enabled state
function AntiDetectionSystem:Toggle()
    isEnabled = not isEnabled
    
    if isEnabled then
        -- Restore hooks
        self:SetupFunctionHooks()
    else
        -- Return control to original functions
        for _, funcName in ipairs(functionsToProtect) do
            if _G[funcName] and functionHooks[funcName] then
                -- Restore original function
                _G[funcName] = functionHooks[funcName]
            end
        end
        
        -- Clear action queue
        actionQueue = {}
    end
    
    -- Update settings
    local settings = ConfigRegistry:GetSettings("AntiDetectionSystem")
    settings.generalSettings.enableAntiDetection = isEnabled
    
    return isEnabled
end

-- Is enabled
function AntiDetectionSystem:IsEnabled()
    return isEnabled
end

-- Is in safe mode
function AntiDetectionSystem:IsInSafeMode()
    return safeModeEnabled
end

-- Get safe mode reason
function AntiDetectionSystem:GetSafeModeReason()
    return safeModeReason
end

-- Get detection level
function AntiDetectionSystem:GetDetectionLevel()
    return detectionLevel
end

-- Get current settings
function AntiDetectionSystem:GetCurrentSettings()
    return {
        minDelay = MIN_DELAY,
        maxDelay = MAX_DELAY,
        jitterFactor = jitterFactor,
        detectionLevel = detectionLevel,
        queueSize = #actionQueue,
        safeModeEnabled = safeModeEnabled
    }
}

-- Get action history
function AntiDetectionSystem:GetActionHistory()
    return actionHistory
end

-- Get action distribution
function AntiDetectionSystem:GetActionDistribution()
    return actionDistribution
end

-- Return the module
return AntiDetectionSystem