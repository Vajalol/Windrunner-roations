------------------------------------------
-- WindrunnerRotations - Auto Targeting
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local AutoTargeting = {}
WR.AutoTargeting = AutoTargeting

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local InterruptManager = WR.InterruptManager
local TargetPrioritySystem = WR.TargetPrioritySystem
local GroupRoleManager = WR.GroupRoleManager
local PvPManager = WR.PvPManager

-- Data storage
local isEnabled = true
local autoTargetEnabled = true
local autoRetargetEnabled = true
local targetScanFrequency = 0.2
local lastTargetScan = 0
local targetableFriendlyUnits = {}
local targetableEnemyUnits = {}
local targetPriorities = {}
local currentTargetGUID = nil
local previousTargetGUID = nil
local mouseoverUnitGUID = nil
local targetLossTime = nil
local instanceType = "none"
local specialUnitHandling = {}
local ccTracker = {}
local avoidanceTracking = {}
local primaryTargetAssistActive = false
local targetAssistUnit = nil
local preventAutoSwitching = false
local autoRetargetDelay = 0.5
local combatTime = 0
local inInstance = false
local targetSelectionMethod = "priority"
local targetSwitchActiveCD = false
local targetSelectionScore = {}
local unitBlacklist = {}
local unitWhitelist = {}
local threatBasedTargetingEnabled = true
local targetingPaused = false
local pausedUntil = 0
local nameplateScanEnabled = true
local nearbyUnitScanEnabled = true
local petAttackEnabled = true
local focusTargetSyncEnabled = false
local avoidTargetSwitchingDuringCast = true
local lastCastTarget = nil
local unitExpiryTime = 2.0 -- Time before considering unit data outdated
local rangeCheckEnabled = true
local offTankTargetAvoidance = true
local lastTargetSwitch = 0
local minimumTargetSwitchCooldown = 1.0 -- Minimum time between target switches
local maxTargetDistance = 40 -- Max distance to consider a target
local lastFriendlyScan = 0
local lastEnemyScan = 0
local friendlyScanFrequency = 1.0
local enemyScanFrequency = 0.5

-- Constants
local TARGET_TYPE_ENEMY = "enemy"
local TARGET_TYPE_FRIENDLY = "friendly"
local PRIORITY_CRITICAL = 5
local PRIORITY_HIGH = 4
local PRIORITY_MEDIUM = 3
local PRIORITY_NORMAL = 2
local PRIORITY_LOW = 1

-- Initialize the Auto Targeting
function AutoTargeting:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize target priorities
    self:InitializeTargetPriorities()
    
    -- Check player role and spec
    self:UpdateRoleSpecificSettings()
    
    -- Setup initial timers
    lastTargetScan = GetTime()
    lastFriendlyScan = GetTime()
    lastEnemyScan = GetTime()
    
    API.PrintDebug("Auto Targeting initialized")
    return true
end

-- Register settings
function AutoTargeting:RegisterSettings()
    ConfigRegistry:RegisterSettings("AutoTargeting", {
        generalSettings = {
            enableAutoTargeting = {
                displayName = "Enable Auto Targeting",
                description = "Automatically select targets based on priority",
                type = "toggle",
                default = true
            },
            enableRetargeting = {
                displayName = "Auto Re-target",
                description = "Automatically find a new target when current target dies or becomes invalid",
                type = "toggle",
                default = true
            },
            targetScanFrequency = {
                displayName = "Target Scan Frequency",
                description = "How often to scan for new targets (seconds)",
                type = "slider",
                min = 0.1,
                max = 1.0,
                step = 0.1,
                default = 0.2
            },
            targetSelectionMethod = {
                displayName = "Target Selection Method",
                description = "Method to use when selecting targets",
                type = "dropdown",
                options = {"Priority", "Distance", "Health", "Threat", "Tank Assist", "Focus Target", "Custom"},
                default = "Priority"
            },
            maximumTargetDistance = {
                displayName = "Maximum Target Distance",
                description = "Maximum distance to consider a target (yards)",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 40
            }
        },
        targetPrioritySettings = {
            prioritizeCasters = {
                displayName = "Prioritize Casters",
                description = "Give higher priority to enemy casters",
                type = "toggle",
                default = true
            },
            prioritizeLowHealth = {
                displayName = "Prioritize Low Health",
                description = "Give higher priority to low health enemies",
                type = "toggle",
                default = true
            },
            lowHealthThreshold = {
                displayName = "Low Health Threshold",
                description = "Health percentage to consider as low",
                type = "slider",
                min = 5,
                max = 50,
                step = 5,
                default = 20
            },
            prioritizeElites = {
                displayName = "Prioritize Elites",
                description = "Give higher priority to elite enemies",
                type = "toggle",
                default = true
            },
            prioritizeBoss = {
                displayName = "Prioritize Bosses",
                description = "Give higher priority to boss enemies",
                type = "toggle",
                default = true
            }
        },
        pvpSettings = {
            enablePvPTargeting = {
                displayName = "Enable PvP Targeting",
                description = "Use specialized targeting for PvP scenarios",
                type = "toggle",
                default = true
            },
            prioritizeHealers = {
                displayName = "Prioritize Healers",
                description = "Give higher priority to enemy healers in PvP",
                type = "toggle",
                default = true
            },
            prioritizeFlag = {
                displayName = "Prioritize Flag Carriers",
                description = "Give higher priority to enemy flag carriers",
                type = "toggle",
                default = true
            },
            targetEnemyFocusTarget = {
                displayName = "Target Enemy Focus Target",
                description = "Target your target's target for better coordination",
                type = "toggle",
                default = true
            },
            prioritizePlayerClass = {
                displayName = "Prioritize by Class",
                description = "Class priority for target selection in PvP",
                type = "multiselect",
                options = {"Healer > Cloth > Leather > Mail > Plate", "Healer > DPS > Tank", "Custom Class Priority", "Disable Class Priority"},
                default = "Healer > DPS > Tank"
            }
        },
        instanceSettings = {
            mythicPlusPriority = {
                displayName = "Mythic+ Priority",
                description = "Target priority in Mythic+ dungeons",
                type = "dropdown",
                options = {"Priority Targets", "Tank's Target", "Lowest Health", "Nearest Enemy", "Custom NPC Priority"},
                default = "Priority Targets"
            },
            raidPriority = {
                displayName = "Raid Priority",
                description = "Target priority in Raids",
                type = "dropdown",
                options = {"Boss Only", "Current Boss Phase Mechanics", "Tank's Target", "Custom NPC Priority"},
                default = "Current Boss Phase Mechanics"
            },
            threatBasedTargeting = {
                displayName = "Threat-Based Targeting",
                description = "Adjust targeting based on threat levels",
                type = "toggle",
                default = true
            },
            avoidOffTankTargets = {
                displayName = "Avoid Off-Tank Targets",
                description = "Avoid targeting enemies that off-tanks are focused on",
                type = "toggle",
                default = true
            }
        },
        advancedSettings = {
            targetSwitchCooldown = {
                displayName = "Target Switch Cooldown",
                description = "Minimum time between target switches (seconds)",
                type = "slider",
                min = 0.5,
                max = 5.0,
                step = 0.5,
                default = 1.0
            },
            scanNameplates = {
                displayName = "Scan Nameplates",
                description = "Scan nameplate units for targeting",
                type = "toggle",
                default = true
            },
            scanNearbyUnits = {
                displayName = "Scan Nearby Units",
                description = "Scan nearby units for targeting",
                type = "toggle",
                default = true
            },
            enablePetAttack = {
                displayName = "Enable Pet Attack",
                description = "Command pet to attack current target",
                type = "toggle",
                default = true
            },
            syncWithFocusTarget = {
                displayName = "Sync with Focus Target",
                description = "Attempt to target the same target as your focus",
                type = "toggle",
                default = false
            },
            avoidSwitchingDuringCast = {
                displayName = "Avoid Switching During Cast",
                description = "Avoid switching targets while casting",
                type = "toggle",
                default = true
            },
            rangeCheck = {
                displayName = "Range Check",
                description = "Only target enemies within range of your abilities",
                type = "toggle",
                default = true
            }
        }
    })
end

-- Register for events
function AutoTargeting:RegisterEvents()
    -- Register for combat events
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnEnterCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnLeaveCombat()
    end)
    
    -- Register for target changes
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:OnTargetChanged()
    end)
    
    -- Register for focus changes
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:OnFocusChanged()
    end)
    
    -- Register for mouseover changes
    API.RegisterEvent("UPDATE_MOUSEOVER_UNIT", function()
        self:OnMouseoverChanged()
    end)
    
    -- Register for unit health changes
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        self:OnUnitHealthChanged(unit)
    end)
    
    -- Register for unit flags/status changes
    API.RegisterEvent("UNIT_FLAGS", function(unit)
        self:OnUnitFlagsChanged(unit)
    end)
    
    -- Register for nameplate changes
    API.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
        self:OnNameplateAdded(unit)
    end)
    
    API.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
        self:OnNameplateRemoved(unit)
    end)
    
    -- Register for player entering world/zone change
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:OnPlayerEnteringWorld()
    end)
    
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
    
    -- Register for spell casting
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit)
        if unit == "player" then
            self:OnPlayerCastStart()
        else
            self:OnUnitCastStart(unit)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_STOP", function(unit)
        if unit == "player" then
            self:OnPlayerCastStop()
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
        if unit == "player" then
            self:OnPlayerCastSuccess(spellID)
        end
    end)
    
    -- Register for pet events (for classes with pets)
    API.RegisterEvent("UNIT_PET", function(unit)
        if unit == "player" then
            self:OnPetChanged()
        end
    end)
    
    -- Register for CC breaks
    API.RegisterEvent("LOSS_OF_CONTROL_ADDED", function()
        self:OnLossOfControlAdded()
    end)
    
    API.RegisterEvent("LOSS_OF_CONTROL_UPDATE", function()
        self:OnLossOfControlUpdate()
    end)
    
    -- Register for instance information
    API.RegisterEvent("CHALLENGE_MODE_START", function()
        self:OnChallengeStart()
    end)
    
    API.RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, groupSize)
        self:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    end)
    
    API.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
        self:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    end)
    
    -- Register timer to periodically check for targets
    C_Timer.NewTicker(0.1, function()
        self:OnUpdate()
    end)
}

-- Initialize target priorities
function AutoTargeting:InitializeTargetPriorities()
    -- Basic target types
    targetPriorities = {
        -- Standard priorities for enemy types
        boss = PRIORITY_CRITICAL,
        elite = PRIORITY_HIGH,
        rare = PRIORITY_HIGH,
        caster = PRIORITY_HIGH,
        healer = PRIORITY_HIGH,
        normal = PRIORITY_NORMAL,
        minor = PRIORITY_LOW,
        
        -- PvP priorities
        pvp_healer = PRIORITY_CRITICAL,
        pvp_flag_carrier = PRIORITY_CRITICAL,
        pvp_caster = PRIORITY_HIGH,
        pvp_ranged_dps = PRIORITY_HIGH,
        pvp_melee_dps = PRIORITY_MEDIUM,
        pvp_tank = PRIORITY_LOW,
        
        -- Instance specific 
        dungeon_priority = PRIORITY_CRITICAL,
        dungeon_caster = PRIORITY_HIGH,
        raid_mechanic = PRIORITY_CRITICAL,
        
        -- Special case enemies
        explosive = PRIORITY_CRITICAL,  -- M+ Explosive affix
        spiteful = PRIORITY_NORMAL     -- M+ Spiteful affix
    }
    
    -- Special handling for specific NPCs/units
    specialUnitHandling = {
        -- Example of special handling for specific NPCs by ID
        -- Format: [npcID] = {priority = X, requiresTank = bool, avoidAsDPS = bool, focusInterrupt = bool}
        
        -- Mythic+ Season 2 TWW Affixes
        [203619] = {priority = PRIORITY_CRITICAL, name = "Incorporeal Being", notes = "Affix: Incorporeal"}, -- Incorporeal mob
        [204536] = {priority = PRIORITY_CRITICAL, name = "Afflicted Soul", notes = "Affix: Afflicted"}, -- Afflicted mob
        [204773] = {priority = PRIORITY_HIGH, name = "Mystic Illusion", notes = "Affix: Illusionary"}, -- Illusionary mob
        
        -- Example Dungeons for Season 2 TWW
        -- Atal'Dazar
        [122969] = {priority = PRIORITY_HIGH, name = "Zanchuli Witch-Doctor", focusInterrupt = true},
        [122970] = {priority = PRIORITY_MEDIUM, name = "Shadowblade Stalker"},
        [122984] = {priority = PRIORITY_HIGH, name = "Dazar'ai Juggernaut", requiresTank = true},
        
        -- Black Rook Hold
        [98542] = {priority = PRIORITY_HIGH, name = "Ghostly Councilor", focusInterrupt = true},
        [98691] = {priority = PRIORITY_HIGH, name = "Risen Scout", avoidAsDPS = false},
        [98275] = {priority = PRIORITY_HIGH, name = "Risen Archer", focusInterrupt = false},
        
        -- Waycrest Manor
        [131677] = {priority = PRIORITY_HIGH, name = "Heartsbane Runeweaver", focusInterrupt = true},
        [135474] = {priority = PRIORITY_HIGH, name = "Thistle Acolyte", focusInterrupt = true},
        [135240] = {priority = PRIORITY_MEDIUM, name = "Soul Essence", avoidAsDPS = false},
        
        -- Dawn of the Infinite
        [201223] = {priority = PRIORITY_HIGH, name = "Infinite Chronoweaver", focusInterrupt = true},
        [201222] = {priority = PRIORITY_HIGH, name = "Infinite Timeslicer", avoidAsDPS = false},
        [201792] = {priority = PRIORITY_MEDIUM, name = "Infinite Diversionist", focusInterrupt = false}
    }
}

-- Update role specific settings
function AutoTargeting:UpdateRoleSpecificSettings()
    -- Get player's role from GroupRoleManager if available
    local playerRole = "DPS"
    if GroupRoleManager then
        local role = GroupRoleManager:GetPlayerRole()
        if role == "TANK" then
            playerRole = "TANK"
        elseif role == "HEALER" then
            playerRole = "HEALER"
        end
    end
    
    -- Adjust settings based on role
    if playerRole == "TANK" then
        -- Tanks should target anything, prioritizing threat
        threatBasedTargetingEnabled = true
        targetSelectionMethod = "threat" 
        offTankTargetAvoidance = false
    elseif playerRole == "HEALER" then
        -- Healers get special treatment
        autoTargetEnabled = false  -- Healers typically don't auto-target enemies
        targetSelectionMethod = "tank assist"
    else
        -- DPS uses priority
        targetSelectionMethod = "priority"
        offTankTargetAvoidance = true
    end
    
    -- Check if player has a pet
    local hasActivePet = UnitExists("pet") and not UnitIsDead("pet")
    petAttackEnabled = hasActivePet
}

-- On update (called via ticker)
function AutoTargeting:OnUpdate()
    local now = GetTime()
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    
    -- Update settings if needed
    autoTargetEnabled = settings.generalSettings.enableAutoTargeting
    autoRetargetEnabled = settings.generalSettings.enableRetargeting
    targetScanFrequency = settings.generalSettings.targetScanFrequency
    minimumTargetSwitchCooldown = settings.advancedSettings.targetSwitchCooldown
    maxTargetDistance = settings.generalSettings.maximumTargetDistance
    nameplateScanEnabled = settings.advancedSettings.scanNameplates
    nearbyUnitScanEnabled = settings.advancedSettings.scanNearbyUnits
    petAttackEnabled = settings.advancedSettings.enablePetAttack
    focusTargetSyncEnabled = settings.advancedSettings.syncWithFocusTarget
    avoidTargetSwitchingDuringCast = settings.advancedSettings.avoidSwitchingDuringCast
    rangeCheckEnabled = settings.advancedSettings.rangeCheck
    
    -- Skip if targeting is paused
    if targetingPaused and now < pausedUntil then
        return
    else
        targetingPaused = false
    end
    
    -- Skip if disabled
    if not autoTargetEnabled or not isEnabled then
        return
    end
    
    -- Track combat time
    if UnitAffectingCombat("player") then
        combatTime = combatTime + 0.1
    end
    
    -- Check if it's time to scan for new targets
    if now - lastTargetScan >= targetScanFrequency then
        lastTargetScan = now
        
        -- Perform target scan
        self:ScanForTargets()
    end
    
    -- Check if we should scan friendly units
    if now - lastFriendlyScan >= friendlyScanFrequency then
        lastFriendlyScan = now
        
        -- Scan for friendly units (useful for healers)
        self:ScanForFriendlyTargets()
    end
    
    -- Check if we should scan enemy units
    if now - lastEnemyScan >= enemyScanFrequency then
        lastEnemyScan = now
        
        -- Scan for enemy units
        self:ScanForEnemyTargets()
    end
    
    -- Check if we need to retarget
    if autoRetargetEnabled and self:ShouldRetarget() then
        self:FindAndSetTarget()
    end
    
    -- Command pet to attack if needed
    if petAttackEnabled and UnitExists("pet") and not UnitIsDead("pet") and UnitExists("target") 
       and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") then
        -- Check if pet is already attacking target
        if not UnitIsUnit("target", "pettarget") then
            PetAttack()
        end
    end
}

-- On enter combat
function AutoTargeting:OnEnterCombat()
    combatTime = 0
    
    -- Reset target lists
    self:ResetTargetLists()
    
    -- Initial scan
    self:ScanForTargets()
    
    -- Set initial target if needed
    if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
        self:FindAndSetTarget()
    end
}

-- On leave combat
function AutoTargeting:OnLeaveCombat()
    -- Reset combat time
    combatTime = 0
    
    -- Clear target lists
    self:ResetTargetLists()
    
    -- Reset blacklist/whitelist
    unitBlacklist = {}
    unitWhitelist = {}
}

-- On target changed
function AutoTargeting:OnTargetChanged()
    -- Store current and previous target GUIDs
    previousTargetGUID = currentTargetGUID
    
    if UnitExists("target") then
        currentTargetGUID = UnitGUID("target")
        targetLossTime = nil
        
        -- Track last cast target
        if UnitCastingInfo("player") then
            lastCastTarget = currentTargetGUID
        end
        
        -- Set focus assist if needed
        if focusTargetSyncEnabled and UnitExists("focus") and not UnitIsUnit("focus", "player") then
            local focusTarget = UnitGUID("focustarget")
            if focusTarget and focusTarget ~= UnitGUID("target") then
                -- Store focus target for potential retargeting
                targetAssistUnit = "focus"
            end
        end
        
        -- Update target data
        if UnitCanAttack("player", "target") then
            self:UpdateTargetData("target", TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", "target") then
            self:UpdateTargetData("target", TARGET_TYPE_FRIENDLY)
        end
    else
        currentTargetGUID = nil
        targetLossTime = GetTime()
    end
}

-- On focus changed
function AutoTargeting:OnFocusChanged()
    -- Update focus-related targeting logic
    if focusTargetSyncEnabled and UnitExists("focus") and not UnitIsUnit("focus", "player") then
        -- If focus is a friendly unit (like a tank), we should target what they are targeting
        if UnitIsFriend("player", "focus") then
            targetAssistUnit = "focus"
            
            -- If we don't have a target, immediately target what focus is targeting
            if not UnitExists("target") and UnitExists("focustarget") and 
               UnitCanAttack("player", "focustarget") and not UnitIsDeadOrGhost("focustarget") then
                TargetUnit("focustarget")
            end
        end
    else
        -- Clear focus assist if focus is cleared or invalid
        if targetAssistUnit == "focus" then
            targetAssistUnit = nil
        end
    end
}

-- On mouseover changed
function AutoTargeting:OnMouseoverChanged()
    -- Store mouseover GUID
    if UnitExists("mouseover") then
        mouseoverUnitGUID = UnitGUID("mouseover")
        
        -- Update target data
        if UnitCanAttack("player", "mouseover") then
            self:UpdateTargetData("mouseover", TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", "mouseover") then
            self:UpdateTargetData("mouseover", TARGET_TYPE_FRIENDLY)
        end
    else
        mouseoverUnitGUID = nil
    end
}

-- On unit health changed
function AutoTargeting:OnUnitHealthChanged(unit)
    -- Update target data if it's a relevant unit
    if UnitExists(unit) then
        if UnitCanAttack("player", unit) then
            self:UpdateTargetData(unit, TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", unit) then
            self:UpdateTargetData(unit, TARGET_TYPE_FRIENDLY)
        end
    end
}

-- On unit flags changed
function AutoTargeting:OnUnitFlagsChanged(unit)
    -- Units can change state (become friendly/hostile, etc.), update data
    if UnitExists(unit) then
        -- Update based on unit type
        if UnitCanAttack("player", unit) then
            self:UpdateTargetData(unit, TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", unit) then
            self:UpdateTargetData(unit, TARGET_TYPE_FRIENDLY)
        else
            -- Unit no longer valid, remove from tracking
            self:RemoveUnitFromTracking(UnitGUID(unit))
        end
    end
}

-- On nameplate added
function AutoTargeting:OnNameplateAdded(unit)
    -- Skip if nameplate scanning is disabled
    if not nameplateScanEnabled then
        return
    end
    
    -- Check if this is a valid unit to track
    if UnitExists(unit) then
        -- Update based on unit type
        if UnitCanAttack("player", unit) then
            self:UpdateTargetData(unit, TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", unit) then
            self:UpdateTargetData(unit, TARGET_TYPE_FRIENDLY)
        end
    end
}

-- On nameplate removed
function AutoTargeting:OnNameplateRemoved(unit)
    -- Remove from tracking (actual GUID already gone, so no direct removal)
    -- Instead, our unit update system will expire old entries
}

-- On player entering world
function AutoTargeting:OnPlayerEnteringWorld()
    -- Reset target lists
    self:ResetTargetLists()
    
    -- Check instance type
    local inInstance, instanceType = IsInInstance()
    self.inInstance = inInstance
    self.instanceType = instanceType
    
    -- Adjust settings based on instance type
    self:UpdateInstanceSettings(instanceType)
    
    -- Check player role and spec
    self:UpdateRoleSpecificSettings()
}

-- On zone changed
function AutoTargeting:OnZoneChanged()
    -- Recheck instance type
    local inInstance, instanceType = IsInInstance()
    self.inInstance = inInstance
    self.instanceType = instanceType
    
    -- Adjust settings based on instance type
    self:UpdateInstanceSettings(instanceType)
}

-- On player cast start
function AutoTargeting:OnPlayerCastStart()
    -- Record current target as the cast target
    if UnitExists("target") then
        lastCastTarget = UnitGUID("target")
    end
    
    -- If we're configured to avoid switching during cast, pause targeting
    if avoidTargetSwitchingDuringCast then
        self:PauseTargeting(1.5) -- Pause for 1.5 seconds or until cast ends
    end
}

-- On player cast stop
function AutoTargeting:OnPlayerCastStop()
    -- If targeting was paused due to casting, unpause it
    if targetingPaused and avoidTargetSwitchingDuringCast then
        targetingPaused = false
    end
}

-- On player cast success
function AutoTargeting:OnPlayerCastSuccess(spellID)
    -- Reset last cast target
    lastCastTarget = nil
    
    -- If targeting was paused due to casting, unpause it
    if targetingPaused and avoidTargetSwitchingDuringCast then
        targetingPaused = false
    end
}

-- On unit cast start
function AutoTargeting:OnUnitCastStart(unit)
    -- Check if this is an interruptible cast from an enemy
    if UnitCanAttack("player", unit) and not UnitIsPlayer(unit) then
        local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
        
        if name and not notInterruptible then
            -- This enemy is casting something interruptible, consider targeting
            self:UpdateTargetData(unit, TARGET_TYPE_ENEMY)
            
            -- If we have interrupt capability and no current target, consider switching
            if InterruptManager and InterruptManager:CanInterrupt() then
                -- If we don't have a target, target this unit
                if not UnitExists("target") then
                    TargetUnit(unit)
                    return
                end
                
                -- If our current target isn't casting anything interruptible, consider switching
                if UnitExists("target") and not self:IsUnitCastingInterruptible("target") then
                    -- Check if we're allowed to switch targets now
                    if GetTime() - lastTargetSwitch >= minimumTargetSwitchCooldown then
                        TargetUnit(unit)
                    end
                end
            end
        end
    end
}

-- On pet changed
function AutoTargeting:OnPetChanged()
    -- Update pet attack status
    local hasActivePet = UnitExists("pet") and not UnitIsDead("pet")
    petAttackEnabled = hasActivePet and ConfigRegistry:GetSettings("AutoTargeting").advancedSettings.enablePetAttack
}

-- On loss of control added
function AutoTargeting:OnLossOfControlAdded()
    -- Player has been CCed, make sure we don't switch targets during this time
    targetingPaused = true
    pausedUntil = GetTime() + 3.0 -- Pause for 3 seconds or until control returns
}

-- On loss of control update
function AutoTargeting:OnLossOfControlUpdate()
    -- Player CC status has changed, check if we're still under CC
    local locType = C_LossOfControl.GetActiveLossOfControlData(1)
    
    if not locType then
        -- No more CC, resume targeting
        targetingPaused = false
    end
}

-- On challenge start
function AutoTargeting:OnChallengeStart()
    -- We've started a M+ dungeon, update settings
    self:UpdateInstanceSettings("challenge")
    
    -- Clear and reset targeting data
    self:ResetTargetLists()
}

-- On encounter start
function AutoTargeting:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    -- We've started a boss encounter, update settings
    self:UpdateInstanceSettings("raid")
    
    -- Consider priority targeting based on boss mechanics
    -- In a full implementation, we'd load boss-specific targeting data
}

-- On encounter end
function AutoTargeting:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    -- Encounter ended, reset targeting
    self:ResetTargetLists()
}

-- Update instance settings
function AutoTargeting:UpdateInstanceSettings(instanceType)
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    
    if instanceType == "pvp" or instanceType == "arena" then
        -- PvP targeting settings
        if not settings.pvpSettings.enablePvPTargeting then
            -- PvP targeting disabled, keep standard targeting
            targetSelectionMethod = "priority"
        else
            targetSelectionMethod = "pvp"
        end
    elseif instanceType == "party" then

        -- Dungeon settings
        local dungeonPriority = settings.instanceSettings.mythicPlusPriority
        
        if dungeonPriority == "Priority Targets" then
            targetSelectionMethod = "priority"
        elseif dungeonPriority == "Tank's Target" then
            targetSelectionMethod = "tank assist"
        elseif dungeonPriority == "Lowest Health" then
            targetSelectionMethod = "health"
        elseif dungeonPriority == "Nearest Enemy" then
            targetSelectionMethod = "distance"
        else
            targetSelectionMethod = "priority"
        end
        
        -- Update threat-based settings
        threatBasedTargetingEnabled = settings.instanceSettings.threatBasedTargeting
        offTankTargetAvoidance = settings.instanceSettings.avoidOffTankTargets
    elseif instanceType == "raid" then
        -- Raid settings
        local raidPriority = settings.instanceSettings.raidPriority
        
        if raidPriority == "Boss Only" then
            targetSelectionMethod = "boss"
        elseif raidPriority == "Current Boss Phase Mechanics" then
            targetSelectionMethod = "mechanic"
        elseif raidPriority == "Tank's Target" then
            targetSelectionMethod = "tank assist"
        else
            targetSelectionMethod = "priority"
        end
        
        -- Update threat-based settings
        threatBasedTargetingEnabled = settings.instanceSettings.threatBasedTargeting
        offTankTargetAvoidance = settings.instanceSettings.avoidOffTankTargets
    elseif instanceType == "challenge" then
        -- Mythic+ settings (more specific than party)
        local dungeonPriority = settings.instanceSettings.mythicPlusPriority
        
        if dungeonPriority == "Priority Targets" then
            targetSelectionMethod = "priority"
        elseif dungeonPriority == "Tank's Target" then
            targetSelectionMethod = "tank assist"
        elseif dungeonPriority == "Lowest Health" then
            targetSelectionMethod = "health"
        elseif dungeonPriority == "Nearest Enemy" then
            targetSelectionMethod = "distance"
        else
            targetSelectionMethod = "priority"
        end
        
        -- Update threat-based settings
        threatBasedTargetingEnabled = settings.instanceSettings.threatBasedTargeting
        offTankTargetAvoidance = settings.instanceSettings.avoidOffTankTargets
    else
        -- World content or other
        targetSelectionMethod = "priority"
        threatBasedTargetingEnabled = settings.instanceSettings.threatBasedTargeting
        offTankTargetAvoidance = false
    end
}

-- Reset target lists
function AutoTargeting:ResetTargetLists()
    targetableFriendlyUnits = {}
    targetableEnemyUnits = {}
    lastTargetScan = GetTime()
    lastFriendlyScan = GetTime()
    lastEnemyScan = GetTime()
}

-- Scan for targets
function AutoTargeting:ScanForTargets()
    -- Get scanning method settings
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    
    -- Check if targeting is enabled
    if not autoTargetEnabled or targetingPaused then
        return
    end
    
    -- Scan nameplates if enabled
    if nameplateScanEnabled then
        self:ScanNameplates()
    end
    
    -- Scan nearby units if enabled
    if nearbyUnitScanEnabled then
        self:ScanNearbyUnits()
    end
    
    -- Clean expired units
    self:CleanExpiredUnits()
}

-- Scan nameplates
function AutoTargeting:ScanNameplates()
    -- Get all visible nameplate units
    for i = 1, 40 do  -- Assuming max 40 nameplates
        local unit = "nameplate" .. i
        
        if UnitExists(unit) then
            -- Check if it's a valid unit to track
            if UnitCanAttack("player", unit) then
                self:UpdateTargetData(unit, TARGET_TYPE_ENEMY)
            elseif UnitIsFriend("player", unit) then
                self:UpdateTargetData(unit, TARGET_TYPE_FRIENDLY)
            end
        end
    end
end

-- Scan nearby units
function AutoTargeting:ScanNearbyUnits()
    -- This would use proximity-based detection in a real addon
    -- For our implementation, we'll just check existing units
    
    -- Check if target's target is valid
    if UnitExists("targettarget") and not UnitIsUnit("targettarget", "player") then
        if UnitCanAttack("player", "targettarget") then
            self:UpdateTargetData("targettarget", TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", "targettarget") then
            self:UpdateTargetData("targettarget", TARGET_TYPE_FRIENDLY)
        end
    end
    
    -- Check if focus target is valid
    if UnitExists("focustarget") and not UnitIsUnit("focustarget", "player") then
        if UnitCanAttack("player", "focustarget") then
            self:UpdateTargetData("focustarget", TARGET_TYPE_ENEMY)
        elseif UnitIsFriend("player", "focustarget") then
            self:UpdateTargetData("focustarget", TARGET_TYPE_FRIENDLY)
        end
    end
    
    -- Check if we're in a group and can find more units
    if IsInGroup() then
        -- Check party/raid targets
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                -- Check unit's target
                local targetUnit = unit .. "target"
                
                if UnitExists(targetUnit) then
                    if UnitCanAttack("player", targetUnit) then
                        self:UpdateTargetData(targetUnit, TARGET_TYPE_ENEMY)
                    elseif UnitIsFriend("player", targetUnit) then
                        self:UpdateTargetData(targetUnit, TARGET_TYPE_FRIENDLY)
                    end
                end
            end
        end
    end
}

-- Scan for friendly targets
function AutoTargeting:ScanForFriendlyTargets()
    -- Only necessary for healers
    if WR.GroupRoleManager and WR.GroupRoleManager:GetPlayerRole() ~= "HEALER" then
        return
    end
    
    -- Check player
    self:UpdateTargetData("player", TARGET_TYPE_FRIENDLY)
    
    -- Check pet if exists
    if UnitExists("pet") then
        self:UpdateTargetData("pet", TARGET_TYPE_FRIENDLY)
    end
    
    -- Check if we're in a group
    if IsInGroup() then
        -- Check party/raid members
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                self:UpdateTargetData(unit, TARGET_TYPE_FRIENDLY)
            end
        end
    end
}

-- Scan for enemy targets
function AutoTargeting:ScanForEnemyTargets()
    -- Skip if targeting is disabled or paused
    if not autoTargetEnabled or targetingPaused then
        return
    end
    
    -- Check current target if exists
    if UnitExists("target") and UnitCanAttack("player", "target") then
        self:UpdateTargetData("target", TARGET_TYPE_ENEMY)
    end
    
    -- Check mouseover
    if UnitExists("mouseover") and UnitCanAttack("player", "mouseover") then
        self:UpdateTargetData("mouseover", TARGET_TYPE_ENEMY)
    end
    
    -- Get scanning method settings
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    
    -- Scan nameplates if enabled
    if nameplateScanEnabled then
        for i = 1, 40 do
            local unit = "nameplate" .. i
            
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                self:UpdateTargetData(unit, TARGET_TYPE_ENEMY)
            end
        end
    end
    
    -- Check if we're in a group and can find more enemies
    if IsInGroup() then
        -- Check party/raid targets
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                -- Check unit's target
                local targetUnit = unit .. "target"
                
                if UnitExists(targetUnit) and UnitCanAttack("player", targetUnit) then
                    self:UpdateTargetData(targetUnit, TARGET_TYPE_ENEMY)
                end
            end
        end
    end
}

-- Update target data
function AutoTargeting:UpdateTargetData(unit, unitType)
    -- Skip if unit doesn't exist
    if not UnitExists(unit) then
        return
    end
    
    -- Get unit GUID
    local guid = UnitGUID(unit)
    if not guid then
        return
    end
    
    -- Prepare target data
    local data = {
        guid = guid,
        lastSeen = GetTime(),
        name = UnitName(unit),
        npcID = self:GetNPCID(guid),
        health = UnitHealth(unit),
        maxHealth = UnitHealthMax(unit),
        healthPercent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100,
        distance = API.GetUnitDistance(unit) or 999,
        isBoss = UnitClassification(unit) == "worldboss" or UnitClassification(unit) == "rareelite" or UnitLevel(unit) == -1,
        isElite = UnitClassification(unit) == "elite" or UnitClassification(unit) == "rareelite",
        isRare = UnitClassification(unit) == "rare" or UnitClassification(unit) == "rareelite",
        isCasting = UnitCastingInfo(unit) ~= nil,
        isInterruptible = self:IsUnitCastingInterruptible(unit),
        isDead = UnitIsDead(unit),
        isPlayer = UnitIsPlayer(unit),
        threat = threatBasedTargetingEnabled and UnitThreatSituation("player", unit) or 0,
        inRange = rangeCheckEnabled and API.IsUnitInRange(unit) or true
    }
    
    -- Add class/spec if it's a player
    if data.isPlayer then
        data.class = select(2, UnitClass(unit))
        data.isHealer = self:IsPlayerHealer(unit)
    end
    
    -- Check for special handling
    if data.npcID and specialUnitHandling[data.npcID] then
        data.specialHandling = specialUnitHandling[data.npcID]
    end
    
    -- Store data in appropriate table
    if unitType == TARGET_TYPE_ENEMY then
        targetableEnemyUnits[guid] = data
    elseif unitType == TARGET_TYPE_FRIENDLY then
        targetableFriendlyUnits[guid] = data
    end
end

-- Should retarget
function AutoTargeting:ShouldRetarget()
    -- Skip if targeting is disabled or paused
    if not autoTargetEnabled or not autoRetargetEnabled or targetingPaused then
        return false
    end
    
    -- Check if we're in combat
    if not UnitAffectingCombat("player") then
        return false
    end
    
    -- Check if we have a valid target
    if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
        return false
    end
    
    -- Check if we lost target recently
    if targetLossTime and GetTime() - targetLossTime < autoRetargetDelay then
        return false
    end
    
    -- Check if we're casting and configured to avoid switching during casts
    if avoidTargetSwitchingDuringCast and UnitCastingInfo("player") then
        return false
    end
    
    -- Check if target switch cooldown has passed
    if GetTime() - lastTargetSwitch < minimumTargetSwitchCooldown then
        return false
    end
    
    -- All checks passed, we should retarget
    return true
}

-- Find and set target
function AutoTargeting:FindAndSetTarget()
    -- Skip if targeting is disabled or paused
    if not autoTargetEnabled or targetingPaused then
        return
    end
    
    -- Get target based on current method
    local bestTarget = self:GetBestTarget()
    
    -- If we found a valid target, set it
    if bestTarget then
        -- Check if this is a different target
        if UnitExists("target") and UnitGUID("target") == bestTarget then
            return -- Already targeting this unit
        end
        
        -- Set last target switch time
        lastTargetSwitch = GetTime()
        
        -- Target by GUID (would use API in real addon)
        self:TargetUnitByGUID(bestTarget)
        
        -- Command pet to attack if enabled
        if petAttackEnabled and UnitExists("pet") and not UnitIsDead("pet") then
            PetAttack()
        end
    end
end

-- Get best target
function AutoTargeting:GetBestTarget()
    -- Skip if no enemies found
    if not targetableEnemyUnits or #targetableEnemyUnits == 0 then
        return nil
    end
    
    -- Prepare variables for best target
    local bestGUID = nil
    local bestScore = -999
    
    -- Choose targeting method based on current selection method
    if targetSelectionMethod == "tank assist" then
        -- Find and target what the tank is targeting
        bestGUID = self:GetTankTargetGUID()
    elseif targetSelectionMethod == "health" then
        -- Find lowest health enemy
        bestGUID = self:GetLowestHealthTargetGUID()
    elseif targetSelectionMethod == "distance" then
        -- Find closest enemy
        bestGUID = self:GetClosestTargetGUID()
    elseif targetSelectionMethod == "boss" then
        -- Find boss enemy
        bestGUID = self:GetBossTargetGUID()
    elseif targetSelectionMethod == "pvp" then
        -- Use PvP targeting logic
        bestGUID = self:GetPvPTargetGUID()
    elseif targetSelectionMethod == "threat" then
        -- Use threat-based targeting
        bestGUID = self:GetHighestThreatTargetGUID()
    elseif targetSelectionMethod == "mechanic" then
        -- Use mechanic-based targeting
        bestGUID = self:GetMechanicTargetGUID()
    else -- Default to priority targeting
        -- Score each enemy and find the best one
        for guid, data in pairs(targetableEnemyUnits) do
            -- Skip dead, blacklisted, or out-of-range units
            if data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
                goto continue
            end
            
            -- Skip if unit was seen too long ago
            if GetTime() - data.lastSeen > unitExpiryTime then
                goto continue
            end
            
            -- Skip off-tank targets if configured
            if offTankTargetAvoidance and self:IsOffTankTarget(guid) then
                goto continue
            end
            
            -- Calculate score for this unit
            local score = self:CalculateTargetScore(data)
            
            -- Update best target if this one has a higher score
            if score > bestScore then
                bestScore = score
                bestGUID = guid
            end
            
            ::continue::
        end
    end
    
    return bestGUID
end

-- Calculate target score
function AutoTargeting:CalculateTargetScore(data)
    local score = 0
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    
    -- Base score on unit type
    if data.isBoss then
        score = score + 100 -- Bosses are top priority
    elseif data.isElite then
        score = score + 50 -- Elite mobs are high priority
    elseif data.isRare then
        score = score + 40 -- Rare mobs are high priority
    end
    
    -- Adjust for casting status if we want to prioritize casters
    if settings.targetPrioritySettings.prioritizeCasters and data.isCasting then
        score = score + 30
        
        -- Extra points if it's interruptible
        if data.isInterruptible then
            score = score + 20
        end
    end
    
    -- Adjust for health if we want to prioritize low health
    if settings.targetPrioritySettings.prioritizeLowHealth then
        local threshold = settings.targetPrioritySettings.lowHealthThreshold
        if data.healthPercent <= threshold then
            score = score + 40 * (1 - (data.healthPercent / threshold))
        end
    end
    
    -- Special handling for certain NPCs
    if data.specialHandling then
        score = score + data.specialHandling.priority * 20
    end
    
    -- Players in PvP need special scoring
    if data.isPlayer and (self.instanceType == "pvp" or self.instanceType == "arena") then
        -- Prioritize healers if configured
        if settings.pvpSettings.prioritizeHealers and data.isHealer then
            score = score + 70
        end
        
        -- Adjust based on class if using class priority
        score = score + self:GetPvPClassScore(data.class, data.isHealer)
    end
    
    -- Distance factor - closer targets get priority, but not the main factor
    if data.distance <= maxTargetDistance then
        score = score + (1 - (data.distance / maxTargetDistance)) * 20
    else
        score = score - 50 -- Heavy penalty for being too far away
    end
    
    -- Apply any final adjustments
    
    -- Whitelisted units get a huge bonus
    if unitWhitelist[data.guid] then
        score = score + 200
    end
    
    -- Return the final score
    return score
end

-- Get tank target GUID
function AutoTargeting:GetTankTargetGUID()
    -- Find a tank in the group
    local tankUnit = nil
    
    -- Check if we have GroupRoleManager
    if GroupRoleManager and GroupRoleManager:IsInGroup() then
        -- Check party/raid members
        local prefix = GroupRoleManager:IsInRaid() and "raid" or "party"
        local count = GroupRoleManager:IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
                tankUnit = unit
                break
            end
        end
    end
    
    -- If we found a tank, check its target
    if tankUnit and UnitExists(tankUnit .. "target") and UnitCanAttack("player", tankUnit .. "target") then
        return UnitGUID(tankUnit .. "target")
    end
    
    -- Fallback to target assist unit
    if targetAssistUnit and UnitExists(targetAssistUnit .. "target") and UnitCanAttack("player", targetAssistUnit .. "target") then
        return UnitGUID(targetAssistUnit .. "target")
    end
    
    -- No tank target found, return nil
    return nil
end

-- Get lowest health target GUID
function AutoTargeting:GetLowestHealthTargetGUID()
    local lowestGUID = nil
    local lowestHealth = 100
    
    for guid, data in pairs(targetableEnemyUnits) do
        -- Skip dead, blacklisted, or out-of-range units
        if data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
            goto continue
        end
        
        -- Skip if unit was seen too long ago
        if GetTime() - data.lastSeen > unitExpiryTime then
            goto continue
        end
        
        -- Skip if too far away
        if data.distance > maxTargetDistance then
            goto continue
        end
        
        -- Update lowest if this one has lower health percentage
        if data.healthPercent < lowestHealth then
            lowestHealth = data.healthPercent
            lowestGUID = guid
        end
        
        ::continue::
    end
    
    return lowestGUID
end

-- Get closest target GUID
function AutoTargeting:GetClosestTargetGUID()
    local closestGUID = nil
    local closestDistance = 999
    
    for guid, data in pairs(targetableEnemyUnits) do
        -- Skip dead, blacklisted, or out-of-range units
        if data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
            goto continue
        end
        
        -- Skip if unit was seen too long ago
        if GetTime() - data.lastSeen > unitExpiryTime then
            goto continue
        end
        
        -- Skip if too far away
        if data.distance > maxTargetDistance then
            goto continue
        end
        
        -- Update closest if this one is closer
        if data.distance < closestDistance then
            closestDistance = data.distance
            closestGUID = guid
        end
        
        ::continue::
    end
    
    return closestGUID
end

-- Get boss target GUID
function AutoTargeting:GetBossTargetGUID()
    local bossGUID = nil
    
    for guid, data in pairs(targetableEnemyUnits) do
        -- Skip dead, blacklisted, or out-of-range units
        if data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
            goto continue
        end
        
        -- Skip if unit was seen too long ago
        if GetTime() - data.lastSeen > unitExpiryTime then
            goto continue
        end
        
        -- Skip if too far away
        if data.distance > maxTargetDistance then
            goto continue
        end
        
        -- Found a boss, return it
        if data.isBoss then
            bossGUID = guid
            break
        end
        
        ::continue::
    end
    
    return bossGUID
end

-- Get PvP target GUID
function AutoTargeting:GetPvPTargetGUID()
    local bestGUID = nil
    local bestScore = -999
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    
    -- Skip if PvP targeting is disabled
    if not settings.pvpSettings.enablePvPTargeting then
        return nil
    end
    
    for guid, data in pairs(targetableEnemyUnits) do
        -- Skip non-players, dead, blacklisted, or out-of-range units
        if not data.isPlayer or data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
            goto continue
        end
        
        -- Skip if unit was seen too long ago
        if GetTime() - data.lastSeen > unitExpiryTime then
            goto continue
        end
        
        -- Skip if too far away
        if data.distance > maxTargetDistance then
            goto continue
        end
        
        -- Calculate PvP score
        local score = 0
        
        -- Prioritize healers if configured
        if settings.pvpSettings.prioritizeHealers and data.isHealer then
            score = score + 70
        end
        
        -- Adjust based on class
        score = score + self:GetPvPClassScore(data.class, data.isHealer)
        
        -- Adjust based on health
        if data.healthPercent < 30 then
            score = score + 50 * (1 - (data.healthPercent / 30))
        end
        
        -- Check if this player is focused by teammates
        if self:IsUnitFocusedByTeam(guid) then
            score = score + 40
        end
        
        -- Distance factor
        score = score + (1 - (data.distance / maxTargetDistance)) * 20
        
        -- Update best target if this one has a higher score
        if score > bestScore then
            bestScore = score
            bestGUID = guid
        end
        
        ::continue::
    end
    
    return bestGUID
end

-- Get highest threat target GUID
function AutoTargeting:GetHighestThreatTargetGUID()
    local highestThreatGUID = nil
    local highestThreat = -1
    
    for guid, data in pairs(targetableEnemyUnits) do
        -- Skip dead, blacklisted, or out-of-range units
        if data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
            goto continue
        end
        
        -- Skip if unit was seen too long ago
        if GetTime() - data.lastSeen > unitExpiryTime then
            goto continue
        end
        
        -- Skip if too far away
        if data.distance > maxTargetDistance then
            goto continue
        end
        
        -- Check threat
        if data.threat > highestThreat then
            highestThreat = data.threat
            highestThreatGUID = guid
        end
        
        ::continue::
    end
    
    return highestThreatGUID
end

-- Get mechanic target GUID
function AutoTargeting:GetMechanicTargetGUID()
    -- This would be filled with boss-specific logic in a real addon
    -- For implementation simplicity, we'll first check for special handling NPCs
    
    local mechanicGUID = nil
    
    for guid, data in pairs(targetableEnemyUnits) do
        -- Skip dead, blacklisted, or out-of-range units
        if data.isDead or unitBlacklist[guid] or (rangeCheckEnabled and not data.inRange) then
            goto continue
        end
        
        -- Skip if unit was seen too long ago
        if GetTime() - data.lastSeen > unitExpiryTime then
            goto continue
        end
        
        -- Skip if too far away
        if data.distance > maxTargetDistance then
            goto continue
        end
        
        -- Check if this unit has special handling
        if data.specialHandling and data.specialHandling.priority >= PRIORITY_HIGH then
            mechanicGUID = guid
            break
        end
        
        ::continue::
    end
    
    -- If no mechanic target found, fall back to boss target
    if not mechanicGUID then
        mechanicGUID = self:GetBossTargetGUID()
    end
    
    return mechanicGUID
end

-- Get PvP class score
function AutoTargeting:GetPvPClassScore(class, isHealer)
    -- Default score
    if not class then
        return 0
    end
    
    local settings = ConfigRegistry:GetSettings("AutoTargeting")
    local priorityMode = settings.pvpSettings.prioritizePlayerClass
    
    -- If healer flag is set, always prioritize healers
    if isHealer then
        return 70
    end
    
    if priorityMode == "Healer > Cloth > Leather > Mail > Plate" then
        -- Armor-based priority
        if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" then
            return 60 -- Cloth
        elseif class == "ROGUE" or class == "MONK" or class == "DRUID" or class == "DEMONHUNTER" then
            return 50 -- Leather
        elseif class == "HUNTER" or class == "SHAMAN" or class == "EVOKER" then
            return 40 -- Mail
        else
            return 30 -- Plate
        end
    elseif priorityMode == "Healer > DPS > Tank" then
        -- Role-based priority (we already handled healers)
        if class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" or class == "DEMONHUNTER" or class == "DRUID" then
            -- These classes can be tanks, so slightly lower priority
            return 40
        else
            -- Pure DPS classes
            return 50
        end
    elseif priorityMode == "Custom Class Priority" then
        -- This would be filled with class-specific scores in a real addon
        return 50
    else
        -- No class priority
        return 50
    end
end

-- Is unit focused by team
function AutoTargeting:IsUnitFocusedByTeam(guid)
    if not IsInGroup() then
        return false
    end
    
    -- Check if party/raid members are targeting this unit
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
    local focusCount = 0
    
    for i = 1, count do
        local unit = prefix .. i
        
        if UnitExists(unit .. "target") and UnitGUID(unit .. "target") == guid then
            focusCount = focusCount + 1
            
            -- If 2 or more are targeting it, consider it focused
            if focusCount >= 2 then
                return true
            end
        end
    end
    
    return false
end

-- Is off-tank target
function AutoTargeting:IsOffTankTarget(guid)
    if not IsInGroup() then
        return false
    end
    
    -- First check if we're a tank - if so, no need to avoid
    if GroupRoleManager and GroupRoleManager:GetPlayerRole() == "TANK" then
        return false
    end
    
    -- Check if an off-tank is targeting this unit
    local prefix = IsInRaid() and "raid" or "party"
    local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
    
    for i = 1, count do
        local unit = prefix .. i
        
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "TANK" then
            if UnitExists(unit .. "target") and UnitGUID(unit .. "target") == guid then
                return true
            end
        end
    end
    
    return false
end

-- Clean expired units
function AutoTargeting:CleanExpiredUnits()
    local now = GetTime()
    
    -- Clean enemy units
    for guid, data in pairs(targetableEnemyUnits) do
        if now - data.lastSeen > unitExpiryTime then
            targetableEnemyUnits[guid] = nil
        end
    end
    
    -- Clean friendly units
    for guid, data in pairs(targetableFriendlyUnits) do
        if now - data.lastSeen > unitExpiryTime then
            targetableFriendlyUnits[guid] = nil
        end
    end
}

-- Target unit by GUID
function AutoTargeting:TargetUnitByGUID(guid)
    -- This would use a proper GUID targeting function in a real addon
    -- For implementation, we'll check for unit tokens with this GUID
    
    -- Check current target
    if UnitExists("target") and UnitGUID("target") == guid then
        return true -- Already targeting this unit
    end
    
    -- Check mouseover
    if UnitExists("mouseover") and UnitGUID("mouseover") == guid then
        TargetUnit("mouseover")
        return true
    end
    
    -- Check nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        
        if UnitExists(unit) and UnitGUID(unit) == guid then
            TargetUnit(unit)
            return true
        end
    end
    
    -- Check party/raid targets
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit .. "target") and UnitGUID(unit .. "target") == guid then
                TargetUnit(unit .. "target")
                return true
            end
        end
    end
    
    -- Check target of target
    if UnitExists("targettarget") and UnitGUID("targettarget") == guid then
        TargetUnit("targettarget")
        return true
    end
    
    -- Check focus target
    if UnitExists("focustarget") and UnitGUID("focustarget") == guid then
        TargetUnit("focustarget")
        return true
    end
    
    -- Unit not found by token, would use more advanced methods in real addon
    return false
}

-- Is unit casting interruptible
function AutoTargeting:IsUnitCastingInterruptible(unit)
    -- Check if unit is casting
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    
    if name and not notInterruptible then
        return true
    end
    
    -- Check if unit is channeling
    name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
    
    if name and not notInterruptible then
        return true
    end
    
    return false
}

-- Get NPC ID from GUID
function AutoTargeting:GetNPCID(guid)
    if not guid then
        return nil
    end
    
    local type, _, _, _, _, npcID = strsplit("-", guid)
    
    if type == "Creature" or type == "Vehicle" or type == "Pet" then
        return tonumber(npcID)
    end
    
    return nil
end

-- Is player healer
function AutoTargeting:IsPlayerHealer(unit)
    -- Check if it's a player
    if not UnitIsPlayer(unit) then
        return false
    end
    
    -- Check role via group role
    if UnitGroupRolesAssigned(unit) == "HEALER" then
        return true
    end
    
    -- Check class/spec if available
    local class = select(2, UnitClass(unit))
    
    if class == "PRIEST" or class == "DRUID" or class == "SHAMAN" or class == "MONK" or class == "PALADIN" or class == "EVOKER" then
        -- These classes can be healers, so it's possible
        -- In a real addon, we'd check spec more precisely
        return true
    end
    
    return false
}

-- Remove unit from tracking
function AutoTargeting:RemoveUnitFromTracking(guid)
    if guid then
        targetableEnemyUnits[guid] = nil
        targetableFriendlyUnits[guid] = nil
    end
}

-- Pause targeting
function AutoTargeting:PauseTargeting(duration)
    targetingPaused = true
    pausedUntil = GetTime() + (duration or 1.0)
}

-- Resume targeting
function AutoTargeting:ResumeTargeting()
    targetingPaused = false
}

-- Is auto targeting enabled
function AutoTargeting:IsEnabled()
    return isEnabled and autoTargetEnabled
}

-- Set auto targeting enabled
function AutoTargeting:SetEnabled(enabled)
    isEnabled = enabled
}

-- Toggle auto targeting
function AutoTargeting:Toggle()
    isEnabled = not isEnabled
    return isEnabled
}

-- Get current target data
function AutoTargeting:GetCurrentTargetData()
    if not UnitExists("target") then
        return nil
    end
    
    local guid = UnitGUID("target")
    return targetableEnemyUnits[guid] or nil
}

-- Add unit to blacklist
function AutoTargeting:AddUnitToBlacklist(guid, duration)
    if not guid then
        return
    end
    
    unitBlacklist[guid] = GetTime() + (duration or 5.0)
}

-- Add unit to whitelist
function AutoTargeting:AddUnitToWhitelist(guid, duration)
    if not guid then
        return
    end
    
    unitWhitelist[guid] = GetTime() + (duration or 5.0)
}

-- Return the module
return AutoTargeting