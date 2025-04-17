------------------------------------------
-- WindrunnerRotations - Target Priority System
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local TargetPrioritySystem = {}
WR.TargetPrioritySystem = TargetPrioritySystem

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Data storage
local targetPriorities = {}
local customPriorities = {}
local trackedUnits = {}
local prioritizedTargets = {}
local TARGET_SCAN_FREQUENCY = 0.2
local lastScanTime = 0
local UNIT_CACHE_TIME = 2 -- How long to cache unit info

-- Target selection modes
local TARGET_MODES = {
    SMART = "smart",
    HIGHEST_HEALTH = "highest_health",
    LOWEST_HEALTH = "lowest_health",
    NEAREST = "nearest",
    FURTHEST = "furthest",
    RANDOM = "random",
    CURRENT = "current",
    CUSTOM = "custom",
    BOSS_PRIORITY = "boss_priority"
}

-- Target types
local TARGET_TYPES = {
    BOSS = "boss",
    ELITE = "elite",
    NORMAL = "normal",
    MINOR = "minor",
    FRIENDLY = "friendly"
}

-- Role types
local ROLE_TYPES = {
    TANK = "tank",
    HEALER = "healer",
    DPS = "dps",
    RANGED = "ranged",
    MELEE = "melee",
    UNKNOWN = "unknown"
}

-- Initialize the Target Priority System
function TargetPrioritySystem:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize default priorities
    self:InitializeDefaultPriorities()
    
    -- Start scanning for targets
    self:StartTargetScanner()
    
    API.PrintDebug("Target Priority System initialized")
    return true
end

-- Register settings for the Target Priority System
function TargetPrioritySystem:RegisterSettings()
    ConfigRegistry:RegisterSettings("TargetPrioritySystem", {
        generalSettings = {
            enableTargetPriority = {
                displayName = "Enable Target Priority System",
                description = "Automatically prioritize targets based on settings",
                type = "toggle",
                default = true
            },
            targetMode = {
                displayName = "Target Selection Mode",
                description = "How to prioritize targets",
                type = "dropdown",
                options = {
                    TARGET_MODES.SMART,
                    TARGET_MODES.HIGHEST_HEALTH,
                    TARGET_MODES.LOWEST_HEALTH,
                    TARGET_MODES.NEAREST,
                    TARGET_MODES.FURTHEST,
                    TARGET_MODES.RANDOM,
                    TARGET_MODES.CURRENT,
                    TARGET_MODES.CUSTOM,
                    TARGET_MODES.BOSS_PRIORITY
                },
                default = TARGET_MODES.SMART
            },
            autoSwapTarget = {
                displayName = "Auto Swap Target",
                description = "Automatically swap to optimal target",
                type = "toggle",
                default = false
            },
            swapCooldown = {
                displayName = "Target Swap Cooldown",
                description = "Minimum time between target swaps (seconds)",
                type = "slider",
                min = 0,
                max = 10,
                step = 0.5,
                default = 2
            }
        },
        prioritySettings = {
            prioritizeBosses = {
                displayName = "Prioritize Bosses",
                description = "Always prioritize boss enemies",
                type = "toggle",
                default = true
            },
            prioritizeLowHealth = {
                displayName = "Prioritize Low Health",
                description = "Prioritize enemies with low health for execute phase",
                type = "toggle",
                default = true
            },
            lowHealthThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage to consider as low",
                type = "slider",
                min = 0,
                max = 50,
                step = 5,
                default = 20
            },
            aoeTargetCount = {
                displayName = "AoE Target Count",
                description = "Minimum number of targets to use AoE",
                type = "slider",
                min = 2,
                max = 10,
                step = 1,
                default = 3
            }
        },
        roleSettings = {
            prioritizeByRole = {
                displayName = "Prioritize by Role",
                description = "Prioritize targets based on their role",
                type = "toggle",
                default = true
            },
            rolePriority = {
                displayName = "Role Priority",
                description = "Priority of different roles",
                type = "multiselect",
                options = {
                    ROLE_TYPES.HEALER,
                    ROLE_TYPES.TANK,
                    ROLE_TYPES.RANGED,
                    ROLE_TYPES.MELEE
                },
                default = {
                    ROLE_TYPES.HEALER,
                    ROLE_TYPES.RANGED,
                    ROLE_TYPES.MELEE,
                    ROLE_TYPES.TANK
                }
            },
            ignoreTargetsAboveHealth = {
                displayName = "Ignore Targets Above Health",
                description = "Ignore targets with health above this percentage when prioritizing",
                type = "slider",
                min = 0,
                max = 100,
                step = 5,
                default = 100
            }
        },
        additionalSettings = {
            prioritizeDebuffed = {
                displayName = "Prioritize Debuffed Targets",
                description = "Prioritize targets with your debuffs",
                type = "toggle",
                default = true
            },
            prioritizeInterruptable = {
                displayName = "Prioritize Interruptable Casters",
                description = "Prioritize targets casting interruptable spells",
                type = "toggle",
                default = true
            },
            excludeFriendlyNPCs = {
                displayName = "Exclude Friendly NPCs",
                description = "Don't include friendly NPCs in target priority",
                type = "toggle",
                default = true
            },
            focusTargetPriority = {
                displayName = "Focus Target Priority Bonus",
                description = "Additional priority for focus target",
                type = "slider",
                min = 0,
                max = 100,
                step = 10,
                default = 50
            }
        },
        pvpSettings = {
            enableInPvP = {
                displayName = "Enable in PvP",
                description = "Enable automatic target priority in PvP",
                type = "toggle",
                default = true
            },
            pvpRolePriority = {
                displayName = "PvP Role Priority",
                description = "Priority of different roles in PvP",
                type = "multiselect",
                options = {
                    ROLE_TYPES.HEALER,
                    ROLE_TYPES.RANGED,
                    ROLE_TYPES.MELEE,
                    ROLE_TYPES.TANK
                },
                default = {
                    ROLE_TYPES.HEALER,
                    ROLE_TYPES.RANGED,
                    ROLE_TYPES.MELEE,
                    ROLE_TYPES.TANK
                }
            },
            prioritizeControlled = {
                displayName = "Prioritize Controlled Targets",
                description = "Prioritize enemies under crowd control",
                type = "toggle",
                default = false
            },
            prioritizeLowHealth = {
                displayName = "Prioritize Low Health in PvP",
                description = "Prioritize low health enemies in PvP",
                type = "toggle",
                default = true
            }
        },
        debugSettings = {
            showTargetScores = {
                displayName = "Show Target Scores",
                description = "Show priority scores for targets",
                type = "toggle",
                default = false
            },
            showRecommendedTarget = {
                displayName = "Show Recommended Target",
                description = "Highlight the recommended target",
                type = "toggle",
                default = true
            },
            showTargetPriorityTrace = {
                displayName = "Show Priority Calculation",
                description = "Show detailed calculation of target priorities",
                type = "toggle",
                default = false
            }
        }
    })
end

-- Register for events
function TargetPrioritySystem:RegisterEvents()
    -- Register for combat events
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnCombatStart()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnCombatEnd()
    end)
    
    -- Register for target changes
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:OnTargetChanged()
    end)
    
    -- Register for focus changes
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:OnFocusChanged()
    end)
    
    -- Register for name plates
    API.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
        self:OnNameplateAdded(unit)
    end)
    
    API.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
        self:OnNameplateRemoved(unit)
    end)
    
    -- Register for zone changes
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
    
    -- Register for boss detection
    API.RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", function()
        self:OnBossEngaged()
    end)
    
    -- Register for unit health changes
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        self:OnUnitHealthChanged(unit)
    end)
    
    -- Register for unit aura changes
    API.RegisterEvent("UNIT_AURA", function(unit)
        self:OnUnitAuraChanged(unit)
    end)
    
    -- Register for spell casts
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit)
        self:OnUnitSpellcastStart(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_STOP", function(unit)
        self:OnUnitSpellcastStop(unit)
    end)
    
    -- Register for group updates
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:OnGroupUpdate()
    end)
    
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
end

-- Initialize default priorities
function TargetPrioritySystem:InitializeDefaultPriorities()
    -- Set default priorities based on unit types
    targetPriorities = {
        [TARGET_TYPES.BOSS] = 100,
        [TARGET_TYPES.ELITE] = 80,
        [TARGET_TYPES.NORMAL] = 50,
        [TARGET_TYPES.MINOR] = 20,
        [TARGET_TYPES.FRIENDLY] = 0
    }
    
    -- Set default priorities based on roles
    targetPriorities.roles = {
        [ROLE_TYPES.HEALER] = 90,
        [ROLE_TYPES.RANGED] = 70,
        [ROLE_TYPES.MELEE] = 60,
        [ROLE_TYPES.TANK] = 40,
        [ROLE_TYPES.UNKNOWN] = 50
    }
    
    -- Initialize the customPriorities table
    customPriorities = {}
    
    -- Load any saved custom priorities (would be from SavedVariables in a real addon)
    self:LoadCustomPriorities()
    
    -- Initialize prioritized targets
    prioritizedTargets = {
        bestTarget = nil,
        bestTargetScore = 0,
        targets = {},
        lastUpdate = 0
    }
end

-- Start the target scanner
function TargetPrioritySystem:StartTargetScanner()
    -- Start a ticker to scan for targets
    C_Timer.NewTicker(TARGET_SCAN_FREQUENCY, function()
        self:ScanTargets()
    end)
}

-- Scan for targets
function TargetPrioritySystem:ScanTargets()
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    
    -- Skip if disabled
    if not settings.generalSettings.enableTargetPriority then
        return
    end
    
    -- Skip if not in combat (but continue if auto-swap is enabled)
    if not UnitAffectingCombat("player") and not settings.generalSettings.autoSwapTarget then
        return
    end
    
    -- Get current time
    local now = GetTime()
    
    -- Skip if we've scanned recently
    if now - lastScanTime < TARGET_SCAN_FREQUENCY then
        return
    end
    
    lastScanTime = now
    
    -- Clear old scores
    prioritizedTargets.targets = {}
    prioritizedTargets.bestTarget = nil
    prioritizedTargets.bestTargetScore = 0
    
    -- Check for enemies in range
    self:ScanEnemiesInRange()
    
    -- Sort targets by priority
    self:SortTargetsByPriority()
    
    -- Update target selection if needed
    self:UpdateTargetSelection()
    
    -- Debug output if enabled
    if settings.debugSettings.showTargetScores then
        self:DebugShowTargetScores()
    end
}

-- Scan for enemies in range
function TargetPrioritySystem:ScanEnemiesInRange()
    -- Scan nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        
        if UnitExists(unit) then
            self:EvaluateUnit(unit)
        end
    end
    
    -- Always include target if it exists
    if UnitExists("target") then
        self:EvaluateUnit("target")
    end
    
    -- Always include focus if it exists
    if UnitExists("focus") then
        self:EvaluateUnit("focus")
    end
    
    -- Include any boss units
    for i = 1, 5 do
        local unit = "boss" .. i
        
        if UnitExists(unit) then
            self:EvaluateUnit(unit)
        end
    end
    
    -- Scan arena targets in PvP
    if self:IsInPvPZone() then
        for i = 1, 5 do
            local unit = "arena" .. i
            
            if UnitExists(unit) then
                self:EvaluateUnit(unit)
            end
        end
    end
}

-- Evaluate a unit
function TargetPrioritySystem:EvaluateUnit(unit)
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    
    -- Skip if the unit doesn't exist
    if not UnitExists(unit) then
        return
    end
    
    -- Skip if the unit is dead
    if UnitIsDead(unit) then
        return
    end
    
    -- Skip if the unit is friendly and we're excluding friendlies
    if not UnitCanAttack("player", unit) and settings.additionalSettings.excludeFriendlyNPCs then
        return
    end
    
    -- Skip if the unit is not in combat with us (optional, depends on settings)
    if not UnitAffectingCombat(unit) and not UnitIsUnit(unit, "target") and not UnitIsUnit(unit, "focus") then
        -- We might want to include non-combat units for preemptive targeting
        -- For now, only include if they are the target or focus
    end
    
    -- Score the unit
    local score = self:CalculateUnitScore(unit)
    
    -- Store the unit and score
    local guid = UnitGUID(unit)
    
    -- Skip if guid is null
    if not guid then
        return
    end
    
    prioritizedTargets.targets[guid] = {
        unit = unit,
        guid = guid,
        score = score,
        name = UnitName(unit),
        health = UnitHealth(unit),
        maxHealth = UnitHealthMax(unit),
        distance = self:GetUnitDistance(unit)
    }
    
    -- Update best target if this is better
    if score > prioritizedTargets.bestTargetScore then
        prioritizedTargets.bestTarget = guid
        prioritizedTargets.bestTargetScore = score
    end
}

-- Calculate unit score
function TargetPrioritySystem:CalculateUnitScore(unit)
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    local score = 0
    local traceOutput = ""
    
    -- Get unit classification
    local unitType = self:GetUnitType(unit)
    
    -- Base score from unit type
    score = score + targetPriorities[unitType]
    traceOutput = traceOutput .. "Base score (" .. unitType .. "): " .. targetPriorities[unitType] .. "\n"
    
    -- Adjust for role if enabled
    if settings.roleSettings.prioritizeByRole then
        local role = self:GetUnitRole(unit)
        local roleScore = targetPriorities.roles[role] or targetPriorities.roles[ROLE_TYPES.UNKNOWN]
        
        score = score + roleScore
        traceOutput = traceOutput .. "Role score (" .. role .. "): " .. roleScore .. "\n"
    end
    
    -- Check if unit is boss
    if settings.prioritySettings.prioritizeBosses and self:IsUnitBoss(unit) then
        score = score + 200
        traceOutput = traceOutput .. "Boss bonus: 200\n"
    end
    
    -- Check for low health
    if settings.prioritySettings.prioritizeLowHealth then
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        
        if healthPct <= settings.prioritySettings.lowHealthThreshold then
            local healthBonus = (settings.prioritySettings.lowHealthThreshold - healthPct) * 2
            score = score + healthBonus
            traceOutput = traceOutput .. "Low health bonus: " .. healthBonus .. "\n"
        end
    end
    
    -- Check for debuffs
    if settings.additionalSettings.prioritizeDebuffed and self:HasPlayerDebuffs(unit) then
        score = score + 50
        traceOutput = traceOutput .. "Debuff bonus: 50\n"
    end
    
    -- Check for interruptable casts
    if settings.additionalSettings.prioritizeInterruptable and self:IsUnitInterruptable(unit) then
        score = score + 100
        traceOutput = traceOutput .. "Interruptable cast bonus: 100\n"
    end
    
    -- Check if focus target
    if UnitIsUnit(unit, "focus") then
        score = score + settings.additionalSettings.focusTargetPriority
        traceOutput = traceOutput .. "Focus target bonus: " .. settings.additionalSettings.focusTargetPriority .. "\n"
    end
    
    -- Check if current target
    if UnitIsUnit(unit, "target") then
        score = score + 25
        traceOutput = traceOutput .. "Current target bonus: 25\n"
    end
    
    -- Check PvP-specific settings
    if self:IsPlayerUnit(unit) then
        if settings.pvpSettings.enableInPvP then
            -- Apply PvP-specific scoring
            score = self:CalculatePvPUnitScore(unit, score)
            traceOutput = traceOutput .. "PvP scoring applied\n"
        end
    end
    
    -- Apply custom priority if available
    local guid = UnitGUID(unit)
    if customPriorities[guid] then
        score = score + customPriorities[guid]
        traceOutput = traceOutput .. "Custom priority: " .. customPriorities[guid] .. "\n"
    end
    
    -- Save trace for debugging
    if settings.debugSettings.showTargetPriorityTrace then
        API.PrintDebug("Priority calculation for " .. UnitName(unit) .. ":\n" .. traceOutput)
    end
    
    return score
end

-- Calculate PvP-specific unit score
function TargetPrioritySystem:CalculatePvPUnitScore(unit, baseScore)
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    local score = baseScore
    
    -- Get unit role in PvP
    local role = self:GetUnitPvPRole(unit)
    
    -- Apply PvP role priority
    local pvpRolePriority = settings.pvpSettings.pvpRolePriority
    local roleIndex = 1
    
    for i, r in ipairs(pvpRolePriority) do
        if r == role then
            roleIndex = i
            break
        end
    end
    
    -- Higher priority roles get more points
    score = score + (100 - (roleIndex * 20))
    
    -- Check for controlled targets
    if settings.pvpSettings.prioritizeControlled and self:IsUnitControlled(unit) then
        score = score + 50
    end
    
    -- Check for low health in PvP
    if settings.pvpSettings.prioritizeLowHealth then
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        
        if healthPct <= 30 then
            score = score + (30 - healthPct) * 3
        end
    end
    
    return score
end

-- Sort targets by priority
function TargetPrioritySystem:SortTargetsByPriority()
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    local mode = settings.generalSettings.targetMode
    
    -- For certain modes, we need to re-calculate the best target
    if mode == TARGET_MODES.HIGHEST_HEALTH or
       mode == TARGET_MODES.LOWEST_HEALTH or
       mode == TARGET_MODES.NEAREST or
       mode == TARGET_MODES.FURTHEST or
       mode == TARGET_MODES.RANDOM then
        
        local bestGuid = nil
        local bestValue = nil
        
        for guid, data in pairs(prioritizedTargets.targets) do
            local value = nil
            
            if mode == TARGET_MODES.HIGHEST_HEALTH then
                value = data.health
                if not bestValue or value > bestValue then
                    bestValue = value
                    bestGuid = guid
                end
            elseif mode == TARGET_MODES.LOWEST_HEALTH then
                value = data.health
                if not bestValue or value < bestValue then
                    bestValue = value
                    bestGuid = guid
                end
            elseif mode == TARGET_MODES.NEAREST then
                value = data.distance
                if not bestValue or value < bestValue then
                    bestValue = value
                    bestGuid = guid
                end
            elseif mode == TARGET_MODES.FURTHEST then
                value = data.distance
                if not bestValue or value > bestValue then
                    bestValue = value
                    bestGuid = guid
                end
            end
        end
        
        -- Random mode just picks a random target
        if mode == TARGET_MODES.RANDOM then
            local targets = {}
            for guid, _ in pairs(prioritizedTargets.targets) do
                table.insert(targets, guid)
            end
            
            if #targets > 0 then
                bestGuid = targets[math.random(1, #targets)]
            end
        end
        
        -- Update best target
        if bestGuid then
            prioritizedTargets.bestTarget = bestGuid
            prioritizedTargets.bestTargetScore = prioritizedTargets.targets[bestGuid].score
        end
    end
    
    -- Special handling for current target mode
    if mode == TARGET_MODES.CURRENT and UnitExists("target") then
        local targetGUID = UnitGUID("target")
        
        if prioritizedTargets.targets[targetGUID] then
            prioritizedTargets.bestTarget = targetGUID
            prioritizedTargets.bestTargetScore = prioritizedTargets.targets[targetGUID].score
        end
    end
    
    -- Special handling for boss priority mode
    if mode == TARGET_MODES.BOSS_PRIORITY then
        for guid, data in pairs(prioritizedTargets.targets) do
            local unit = data.unit
            
            if self:IsUnitBoss(unit) then
                prioritizedTargets.bestTarget = guid
                prioritizedTargets.bestTargetScore = data.score
                break
            end
        end
    end
    
    -- Update timestamp
    prioritizedTargets.lastUpdate = GetTime()
}

-- Update target selection
function TargetPrioritySystem:UpdateTargetSelection()
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    
    -- Skip if auto-swap is disabled
    if not settings.generalSettings.autoSwapTarget then
        return
    end
    
    -- Skip if there's no best target
    if not prioritizedTargets.bestTarget then
        return
    end
    
    -- Check if we need to swap targets
    local targetGUID = UnitGUID("target")
    local bestTargetGUID = prioritizedTargets.bestTarget
    
    if targetGUID ~= bestTargetGUID then
        -- Get last swap time
        local lastSwapTime = self.lastSwapTime or 0
        local now = GetTime()
        
        -- Check if enough time has passed since last swap
        if now - lastSwapTime >= settings.generalSettings.swapCooldown then
            -- Get the unit ID for the best target
            local bestUnit = prioritizedTargets.targets[bestTargetGUID].unit
            
            -- Swap to the best target
            if bestUnit then
                API.PrintDebug("Auto-swapping to " .. UnitName(bestUnit))
                TargetUnit(bestUnit)
                self.lastSwapTime = now
            end
        end
    end
}

-- Debug show target scores
function TargetPrioritySystem:DebugShowTargetScores()
    API.PrintDebug("Target Priorities:")
    
    for guid, data in pairs(prioritizedTargets.targets) do
        local status = " "
        
        if guid == prioritizedTargets.bestTarget then
            status = "*"
        end
        
        API.PrintDebug(status .. data.name .. ": " .. data.score)
    end
}

-- Get unit type
function TargetPrioritySystem:GetUnitType(unit)
    -- Check if unit is a boss
    if self:IsUnitBoss(unit) then
        return TARGET_TYPES.BOSS
    end
    
    -- Check classification
    local classification = UnitClassification(unit)
    
    if classification == "elite" then
        return TARGET_TYPES.ELITE
    elseif classification == "rare" or classification == "rareelite" then
        return TARGET_TYPES.ELITE
    elseif classification == "normal" then
        return TARGET_TYPES.NORMAL
    elseif classification == "trivial" or classification == "minus" then
        return TARGET_TYPES.MINOR
    end
    
    -- Check if friendly
    if not UnitCanAttack("player", unit) then
        return TARGET_TYPES.FRIENDLY
    end
    
    -- Default
    return TARGET_TYPES.NORMAL
end

-- Check if unit is a boss
function TargetPrioritySystem:IsUnitBoss(unit)
    -- Check if unit is marked as a boss
    if UnitLevel(unit) == -1 then
        return true
    end
    
    -- Check if unit is one of the boss units
    for i = 1, 5 do
        if UnitIsUnit(unit, "boss" .. i) then
            return true
        end
    end
    
    -- Check if unit has the BOSS flag
    local unitFlag = UnitClassification(unit)
    if unitFlag == "worldboss" then
        return true
    end
    
    -- Check by GUID
    local guid = UnitGUID(unit)
    
    if guid then
        -- Parse GUID to check if it's a boss
        local unitType = string.match(guid, "^([^-]+)")
        if unitType == "Boss" then
            return true
        end
    end
    
    return false
}

-- Get unit role
function TargetPrioritySystem:GetUnitRole(unit)
    -- Check if unit is a player
    if UnitIsPlayer(unit) then
        return self:GetUnitPvPRole(unit)
    end
    
    -- For NPCs, try to determine role by name or abilities
    local name = UnitName(unit)
    
    -- Check for common role indicators in name
    if name then
        name = string.lower(name)
        
        if string.find(name, "heal") or
           string.find(name, "priest") or
           string.find(name, "shaman") or
           string.find(name, "medic") then
            return ROLE_TYPES.HEALER
        end
        
        if string.find(name, "guard") or
           string.find(name, "protect") or
           string.find(name, "defend") or
           string.find(name, "warrior") or
           string.find(name, "knight") then
            return ROLE_TYPES.TANK
        end
        
        if string.find(name, "mage") or
           string.find(name, "witch") or
           string.find(name, "caster") or
           string.find(name, "arcanist") or
           string.find(name, "warlock") then
            return ROLE_TYPES.RANGED
        end
    end
    
    -- Try to determine by checking current cast
    local currentCast = UnitCastingInfo(unit)
    
    if currentCast then
        -- This would check the spell against a database of known healing/tank/dps spells
        -- For implementation simplicity, we'll just assume casters are ranged
        return ROLE_TYPES.RANGED
    end
    
    -- Default to melee
    return ROLE_TYPES.MELEE
}

-- Get unit PvP role
function TargetPrioritySystem:GetUnitPvPRole(unit)
    -- Only works for player units
    if not UnitIsPlayer(unit) then
        return ROLE_TYPES.UNKNOWN
    end
    
    -- Get class
    local _, class = UnitClass(unit)
    
    if not class then
        return ROLE_TYPES.UNKNOWN
    end
    
    -- Identify healers
    if class == "PRIEST" or
       class == "DRUID" or
       class == "MONK" or
       class == "PALADIN" or
       class == "SHAMAN" or
       class == "EVOKER" then
        
        -- Check for healing spec by looking for healing auras
        -- This is a simplified approach, real addon would check spec
        if self:HasHealingAuras(unit) then
            return ROLE_TYPES.HEALER
        end
    end
    
    -- Identify tanks
    if class == "WARRIOR" or
       class == "DEATHKNIGHT" or
       class == "PALADIN" or
       class == "DRUID" or
       class == "MONK" or
       class == "DEMONHUNTER" then
        
        -- Check for tank spec by looking for tank auras
        -- This is a simplified approach, real addon would check spec
        if self:HasTankAuras(unit) then
            return ROLE_TYPES.TANK
        end
    end
    
    -- Identify ranged DPS
    if class == "MAGE" or
       class == "WARLOCK" or
       class == "PRIEST" or
       class == "EVOKER" or
       class == "HUNTER" or
       class == "SHAMAN" then
        return ROLE_TYPES.RANGED
    end
    
    -- Everyone else is melee DPS
    return ROLE_TYPES.MELEE
}

-- Check if unit has healing auras
function TargetPrioritySystem:HasHealingAuras(unit)
    -- This would check for specific healing spec auras
    -- For implementation simplicity, we'll just return false
    return false
end

-- Check if unit has tank auras
function TargetPrioritySystem:HasTankAuras(unit)
    -- This would check for specific tank spec auras
    -- For implementation simplicity, we'll just return false
    return false
end

-- Check if unit has player debuffs
function TargetPrioritySystem:HasPlayerDebuffs(unit)
    -- Check if the unit has any of our debuffs
    for i = 1, 40 do
        local _, _, _, _, _, _, caster = UnitDebuff(unit, i)
        
        if caster and UnitIsUnit(caster, "player") then
            return true
        end
    end
    
    return false
end

-- Check if unit is interruptable
function TargetPrioritySystem:IsUnitInterruptable(unit)
    -- Check if unit is casting
    local name, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    
    if name and not notInterruptible then
        return true
    end
    
    -- Check channeled spells too
    name, _, _, _, endTime, _, notInterruptible = UnitChannelInfo(unit)
    
    if name and not notInterruptible then
        return true
    end
    
    return false
end

-- Check if unit is controlled
function TargetPrioritySystem:IsUnitControlled(unit)
    -- Check for CC effects
    for i = 1, 40 do
        local _, _, _, _, _, _, caster, _, _, spellID = UnitDebuff(unit, i)
        
        if caster and UnitIsUnit(caster, "player") then
            -- Check if this is a CC spell
            -- This would check against a database of CC spells
            -- For implementation simplicity, we'll just check a few common ones
            if spellID == 118 or       -- Polymorph
               spellID == 51514 or     -- Hex
               spellID == 20066 or     -- Repentance
               spellID == 6358 or      -- Seduction
               spellID == 605 or       -- Mind Control
               spellID == 339 then     -- Entangling Roots
                return true
            end
        end
    end
    
    return false
end

-- Get unit distance
function TargetPrioritySystem:GetUnitDistance(unit)
    -- In a real addon, this would use actual distance
    -- For implementation simplicity, we'll use a placeholder
    return 10
end

-- Check if unit is a player
function TargetPrioritySystem:IsPlayerUnit(unit)
    -- Check if unit is a player
    return UnitIsPlayer(unit)
end

-- Check if in PvP zone
function TargetPrioritySystem:IsInPvPZone()
    -- Check for arena, battleground, or war mode
    local inArena = IsActiveBattlefieldArena()
    local inBattleground = UnitInBattleground("player")
    local warModeEnabled = C_PvP.IsWarModeDesired()
    
    return inArena or inBattleground or warModeEnabled
end

-- Get the best target
function TargetPrioritySystem:GetBestTarget()
    -- Return the best target
    if not prioritizedTargets.bestTarget then
        return nil
    end
    
    return prioritizedTargets.targets[prioritizedTargets.bestTarget].unit
}

-- Get the N best targets
function TargetPrioritySystem:GetBestTargets(count)
    count = count or 1
    
    -- Create a sorted list of targets
    local sortedTargets = {}
    
    for guid, data in pairs(prioritizedTargets.targets) do
        table.insert(sortedTargets, data)
    end
    
    -- Sort by score
    table.sort(sortedTargets, function(a, b)
        return a.score > b.score
    end)
    
    -- Return the top N
    local result = {}
    
    for i = 1, math.min(count, #sortedTargets) do
        table.insert(result, sortedTargets[i].unit)
    end
    
    return result
end

-- Get targets in cleave range
function TargetPrioritySystem:GetTargetsInCleaveRange(unit, range)
    unit = unit or "target"
    range = range or 8
    
    -- Get targets within range of the specified unit
    local targets = {}
    
    -- In a real addon, this would check actual distances
    -- For implementation simplicity, we'll just return all targets
    for _, data in pairs(prioritizedTargets.targets) do
        table.insert(targets, data.unit)
    end
    
    return targets
end

-- Get the number of targets in cleave range
function TargetPrioritySystem:GetTargetCount(range)
    range = range or 8
    
    -- Get the number of targets within the specified range
    -- In a real addon, this would check actual distances
    -- For implementation simplicity, we'll just count all targets
    local count = 0
    
    for _, _ in pairs(prioritizedTargets.targets) do
        count = count + 1
    end
    
    return count
end

-- Get AoE targets
function TargetPrioritySystem:ShouldUseAoE()
    local settings = ConfigRegistry:GetSettings("TargetPrioritySystem")
    
    -- Check if we have enough targets for AoE
    local count = self:GetTargetCount()
    
    return count >= settings.prioritySettings.aoeTargetCount
end

-- Set custom priority for a unit
function TargetPrioritySystem:SetCustomPriority(guid, priority)
    customPriorities[guid] = priority
    
    -- Save custom priorities
    self:SaveCustomPriorities()
}

-- Clear custom priority for a unit
function TargetPrioritySystem:ClearCustomPriority(guid)
    customPriorities[guid] = nil
    
    -- Save custom priorities
    self:SaveCustomPriorities()
end

-- Save custom priorities
function TargetPrioritySystem:SaveCustomPriorities()
    -- This would save to SavedVariables in a real addon
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("Custom priorities saved")
}

-- Load custom priorities
function TargetPrioritySystem:LoadCustomPriorities()
    -- This would load from SavedVariables in a real addon
    -- For implementation simplicity, we'll just initialize some examples
    customPriorities = {
        ["Player-1"] = 100,
        ["Player-2"] = 50,
        ["Player-3"] = -50
    }
}

-- Handle target changed event
function TargetPrioritySystem:OnTargetChanged()
    -- Update targets when target changes
    self:ScanTargets()
}

-- Handle focus changed event
function TargetPrioritySystem:OnFocusChanged()
    -- Update targets when focus changes
    self:ScanTargets()
}

-- Handle nameplate added event
function TargetPrioritySystem:OnNameplateAdded(unit)
    -- Add unit to tracked units
    local guid = UnitGUID(unit)
    
    if guid then
        trackedUnits[guid] = {
            unit = unit,
            lastUpdate = GetTime()
        }
    end
    
    -- Update targets
    self:ScanTargets()
}

-- Handle nameplate removed event
function TargetPrioritySystem:OnNameplateRemoved(unit)
    -- Remove unit from tracked units
    local guid = UnitGUID(unit)
    
    if guid then
        trackedUnits[guid] = nil
    end
    
    -- Update targets
    self:ScanTargets()
}

-- Handle zone changed event
function TargetPrioritySystem:OnZoneChanged()
    -- Reset tracked units when zone changes
    trackedUnits = {}
    prioritizedTargets.targets = {}
    prioritizedTargets.bestTarget = nil
    prioritizedTargets.bestTargetScore = 0
}

-- Handle boss engaged event
function TargetPrioritySystem:OnBossEngaged()
    -- Update targets when boss is engaged
    self:ScanTargets()
}

-- Handle unit health changed event
function TargetPrioritySystem:OnUnitHealthChanged(unit)
    -- Update targets when unit health changes
    self:ScanTargets()
}

-- Handle unit aura changed event
function TargetPrioritySystem:OnUnitAuraChanged(unit)
    -- Update targets when unit auras change
    self:ScanTargets()
}

-- Handle unit spellcast start event
function TargetPrioritySystem:OnUnitSpellcastStart(unit)
    -- Update targets when unit starts casting
    self:ScanTargets()
}

-- Handle unit spellcast stop event
function TargetPrioritySystem:OnUnitSpellcastStop(unit)
    -- Update targets when unit stops casting
    self:ScanTargets()
}

-- Handle group update event
function TargetPrioritySystem:OnGroupUpdate()
    -- Update targets when group composition changes
    self:ScanTargets()
}

-- Handle combat log event
function TargetPrioritySystem:ProcessCombatLogEvent(...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags = ...
    
    -- Update targets when relevant combat events occur
    if event == "SPELL_DAMAGE" or
       event == "SPELL_PERIODIC_DAMAGE" or
       event == "RANGE_DAMAGE" or
       event == "SWING_DAMAGE" then
        
        -- If the source or destination is the player, update targets
        if sourceGUID == UnitGUID("player") or destGUID == UnitGUID("player") then
            self:ScanTargets()
        end
    end
}

-- Handle combat start event
function TargetPrioritySystem:OnCombatStart()
    -- Start scanning more frequently in combat
    TARGET_SCAN_FREQUENCY = 0.1
}

-- Handle combat end event
function TargetPrioritySystem:OnCombatEnd()
    -- Reduce scanning frequency out of combat
    TARGET_SCAN_FREQUENCY = 0.2
    
    -- Reset targets
    prioritizedTargets.targets = {}
    prioritizedTargets.bestTarget = nil
    prioritizedTargets.bestTargetScore = 0
}

-- Return the module for loading
return TargetPrioritySystem