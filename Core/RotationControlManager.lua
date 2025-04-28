-- RotationControlManager.lua
-- Handles pausing and resuming the rotation system
local addonName, WR = ...
local RotationControlManager = {}
WR.RotationControlManager = RotationControlManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local controlEnabled = true
local pauseRotation = false
local lastPlayerInput = 0
local lastAutoPause = 0
local lastAutoResume = 0
local MIN_AUTO_PAUSE_INTERVAL = 5.0  -- Minimum seconds between auto-pauses
local MIN_AUTO_RESUME_INTERVAL = 2.0  -- Minimum seconds between auto-resumes
local lastKeybindingCheck = 0
local KEYBINDING_CHECK_INTERVAL = 0.5  -- Check keybindings every 0.5 seconds
local playerInputHistory = {}
local MAX_HISTORY_ENTRIES = 10
local customPauseConditions = {}
local manualOverrideKeybindTime = 0
local manualOverrideActive = false
local manualOverrideDuration = 0
local currentPauseReason = ""
local pauseStartTime = 0
local castingTracking = {}

-- Pause triggers
local pauseTriggers = {
    ["MANUAL_KEYBIND"] = {
        priority = 10,
        resumable = true,
        autoResume = false
    },
    ["PLAYER_INPUT"] = {
        priority = 20,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 2.0
    },
    ["IMPORTANT_CAST"] = {
        priority = 30,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 1.0
    },
    ["OUT_OF_COMBAT"] = {
        priority = 40,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 0.5
    },
    ["CUTSCENE"] = {
        priority = 10,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 1.0
    },
    ["NPC_INTERACTION"] = {
        priority = 30,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 0.5
    },
    ["FLIGHT_PATH"] = {
        priority = 10,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 1.0
    },
    ["VEHICLE"] = {
        priority = 10,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 1.0
    },
    ["USER_INTERFACE_OPEN"] = {
        priority = 20,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 1.0
    },
    ["DUNGEON_ROLE_PLAY"] = {
        priority = 10,
        resumable = true,
        autoResume = true,
        autoResumeDelay = 2.0
    }
}

-- Important player spells that should trigger a rotation pause
local importantPlayerSpells = {
    -- Resurrection spells
    [2006] = {name = "Resurrection", duration = 10},  -- Priest
    [7328] = {name = "Redemption", duration = 10},  -- Paladin
    [2008] = {name = "Ancestral Spirit", duration = 10},  -- Shaman
    [115178] = {name = "Resuscitate", duration = 10},  -- Monk
    [50769] = {name = "Revive", duration = 10},  -- Druid
    [361178] = {name = "Mass Resurrection", duration = 10},  -- Mass resurrection
    
    -- Crowd control spells
    [605] = {name = "Mind Control", duration = 0},  -- Priest
    [51514] = {name = "Hex", duration = 1.5},  -- Shaman
    [118] = {name = "Polymorph", duration = 1.7},  -- Mage
    
    -- Important utility spells
    [6201] = {name = "Create Healthstone", duration = 3},  -- Warlock
    [186265] = {name = "Aspect of the Turtle", duration = 8},  -- Hunter
    [1784] = {name = "Stealth", duration = 0},  -- Rogue
    
    -- Portals and teleports
    [3561] = {name = "Teleport: Stormwind", duration = 10},  -- Mage teleport
    [3562] = {name = "Teleport: Ironforge", duration = 10},  -- Mage teleport
    [3563] = {name = "Teleport: Undercity", duration = 10},  -- Mage teleport
    [3565] = {name = "Teleport: Darnassus", duration = 10},  -- Mage teleport
    [3566] = {name = "Teleport: Thunder Bluff", duration = 10},  -- Mage teleport
    [3567] = {name = "Teleport: Orgrimmar", duration = 10},  -- Mage teleport
    [32271] = {name = "Teleport: Exodar", duration = 10},  -- Mage teleport
    [32272] = {name = "Teleport: Silvermoon", duration = 10},  -- Mage teleport
    [49358] = {name = "Teleport: Stonard", duration = 10},  -- Mage teleport
    [49359] = {name = "Teleport: Theramore", duration = 10},  -- Mage teleport
    [33690] = {name = "Teleport: Shattrath", duration = 10},  -- Mage teleport
    [35715] = {name = "Teleport: Shattrath", duration = 10},  -- Mage teleport
    [53140] = {name = "Teleport: Dalaran", duration = 10},  -- Mage teleport
    [88342] = {name = "Teleport: Tol Barad", duration = 10},  -- Mage teleport
    [88344] = {name = "Teleport: Tol Barad", duration = 10},  -- Mage teleport
    [132621] = {name = "Teleport: Vale of Eternal Blossoms", duration = 10},  -- Mage teleport
    [132627] = {name = "Teleport: Vale of Eternal Blossoms", duration = 10},  -- Mage teleport
    [176242] = {name = "Teleport: Warspear", duration = 10},  -- Mage teleport
    [176248] = {name = "Teleport: Stormshield", duration = 10},  -- Mage teleport
    [224869] = {name = "Teleport: Dalaran - Broken Isles", duration = 10},  -- Mage teleport
    [281403] = {name = "Teleport: Boralus", duration = 10},  -- Mage teleport
    [281404] = {name = "Teleport: Dazar'alor", duration = 10},  -- Mage teleport
    [344587] = {name = "Teleport: Oribos", duration = 10},  -- Mage teleport
    [395277] = {name = "Teleport: Valdrakken", duration = 10},  -- Mage teleport
    
    -- Portal spells (similar list to teleports but with portal IDs)
    -- More spells would be added in a complete implementation
}

-- UI panels that should trigger a rotation pause
local pauseOnUIPanels = {
    ["GossipFrame"] = true,
    ["MerchantFrame"] = true,
    ["QuestFrame"] = true,
    ["BankFrame"] = true,
    ["GuildBankFrame"] = true,
    ["AuctionHouseFrame"] = true,
    ["TradeSkillFrame"] = true,
    ["CraftFrame"] = true,
    ["MailFrame"] = true,
    ["LootFrame"] = true,
    ["PvPUIFrame"] = true,
    ["CollectionsJournal"] = true,
    ["PVEFrame"] = true,
    ["AchievementFrame"] = true,
    ["CommunitiesFrame"] = true,
    ["TalentFrame"] = true,
    ["EncounterJournal"] = true,
    ["WeeklyRewardsFrame"] = true,
    ["ExpansionLandingPageMinimapButton"] = true
}

-- Initialize module
function RotationControlManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events for player input tracking
    API.RegisterEvent("PLAYER_STARTED_MOVING", function()
        self:OnPlayerInput("MOVEMENT")
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unitTarget, castGUID, spellID)
        if unitTarget == "player" then
            self:OnPlayerCastStart(spellID, castGUID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unitTarget, castGUID, spellID)
        if unitTarget == "player" then
            self:OnPlayerCastSucceeded(spellID, castGUID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_STOP", function(unitTarget, castGUID, spellID)
        if unitTarget == "player" then
            self:OnPlayerCastStop(spellID, castGUID)
        end
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(unitTarget, castGUID, spellID)
        if unitTarget == "player" then
            self:OnPlayerCastInterrupted(spellID, castGUID)
        end
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnLeaveCombat()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnEnterCombat()
    end)
    
    API.RegisterEvent("CINEMATIC_START", function()
        self:PauseRotation("CUTSCENE")
    end)
    
    API.RegisterEvent("CINEMATIC_STOP", function()
        self:HandleAutoResume("CUTSCENE")
    end)
    
    API.RegisterEvent("PLAYER_CONTROL_LOST", function()
        self:PauseRotation("VEHICLE")
    end)
    
    API.RegisterEvent("PLAYER_CONTROL_GAINED", function()
        self:HandleAutoResume("VEHICLE")
    end)
    
    API.RegisterEvent("TAXIMAP_OPENED", function()
        self:PauseRotation("FLIGHT_PATH")
    end)
    
    API.RegisterEvent("GOSSIP_SHOW", function()
        self:PauseRotation("NPC_INTERACTION")
    end)
    
    API.RegisterEvent("GOSSIP_CLOSED", function()
        self:HandleAutoResume("NPC_INTERACTION")
    end)
    
    -- Hook show/hide methods of major UI frames
    for frameName, _ in pairs(pauseOnUIPanels) do
        if _G[frameName] then
            -- Hook the Show method
            hooksecurefunc(_G[frameName], "Show", function()
                self:OnUIPanelShown(frameName)
            end)
            
            -- Hook the Hide method
            hooksecurefunc(_G[frameName], "Hide", function()
                self:OnUIPanelHidden(frameName)
            end)
        end
    end
    
    -- Register custom slash command for manual pause/resume
    SLASH_WRPAUSE1 = "/wrpause"
    SlashCmdList["WRPAUSE"] = function(msg)
        if pauseRotation then
            self:ResumeRotation("MANUAL_COMMAND")
        else
            local duration = tonumber(msg) or 60  -- Default to 60 seconds
            self:PauseRotation("MANUAL_COMMAND", duration)
        end
    end
    
    API.PrintDebug("Rotation Control Manager initialized")
    return true
end

-- Register settings
function RotationControlManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("RotationControlManager", {
        controlSettings = {
            enableRotationControl = {
                displayName = "Enable Rotation Control",
                description = "Allow for automatic pausing and resuming of rotations",
                type = "toggle",
                default = true
            },
            pauseOnPlayerInput = {
                displayName = "Pause on Player Input",
                description = "Pause rotation when you manually cast spells",
                type = "toggle",
                default = true
            },
            autoResumeAfterInput = {
                displayName = "Auto Resume After Input",
                description = "Automatically resume rotation after manual input",
                type = "toggle",
                default = true
            },
            autoResumeDelay = {
                displayName = "Auto Resume Delay",
                description = "Seconds to wait before auto-resuming rotation",
                type = "slider",
                min = 0.5,
                max = 5.0,
                step = 0.5,
                default = 2.0
            },
            pauseOutOfCombat = {
                displayName = "Pause Out of Combat",
                description = "Automatically pause rotation when leaving combat",
                type = "toggle",
                default = true
            },
            pauseOnImportantCasts = {
                displayName = "Pause on Important Casts",
                description = "Pause when casting important spells like resurrections",
                type = "toggle",
                default = true
            },
            customPauseKeybind = {
                displayName = "Custom Pause Keybind",
                description = "Press this key to pause rotation for a short time",
                type = "keybind",
                default = "ALT-P"
            },
            customPauseDuration = {
                displayName = "Custom Pause Duration",
                description = "Seconds to pause when using the custom keybind",
                type = "slider",
                min = 1,
                max = 60,
                step = 1,
                default = 5
            },
            showPauseStatus = {
                displayName = "Show Pause Status",
                description = "Show on-screen indicator when rotation is paused",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("RotationControlManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function RotationControlManager:ApplySettings(settings)
    -- Apply control settings
    controlEnabled = settings.controlSettings.enableRotationControl
    pauseOnPlayerInput = settings.controlSettings.pauseOnPlayerInput
    autoResumeAfterInput = settings.controlSettings.autoResumeAfterInput
    autoResumeDelay = settings.controlSettings.autoResumeDelay
    pauseOutOfCombat = settings.controlSettings.pauseOutOfCombat
    pauseOnImportantCasts = settings.controlSettings.pauseOnImportantCasts
    customPauseKeybind = settings.controlSettings.customPauseKeybind
    customPauseDuration = settings.controlSettings.customPauseDuration
    showPauseStatus = settings.controlSettings.showPauseStatus
    
    -- Update pause triggers with new settings
    pauseTriggers["PLAYER_INPUT"].autoResume = autoResumeAfterInput
    pauseTriggers["PLAYER_INPUT"].autoResumeDelay = autoResumeDelay
    
    API.PrintDebug("Rotation Control Manager settings applied")
end

-- Update settings from external source
function RotationControlManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.controlEnabled ~= nil then
        controlEnabled = newSettings.controlEnabled
    end
    
    if newSettings.pauseRotation ~= nil then
        if newSettings.pauseRotation and not pauseRotation then
            RotationControlManager:PauseRotation("EXTERNAL")
        elseif not newSettings.pauseRotation and pauseRotation then
            RotationControlManager:ResumeRotation("EXTERNAL")
        end
    end
end

-- Pause the rotation
function RotationControlManager:PauseRotation(reason, duration)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Skip if already paused for a higher priority reason
    if pauseRotation and pauseTriggers[currentPauseReason] and pauseTriggers[reason] and 
       pauseTriggers[currentPauseReason].priority < pauseTriggers[reason].priority then
        return
    end
    
    -- Pause rotation
    pauseRotation = true
    currentPauseReason = reason
    pauseStartTime = GetTime()
    
    -- Set auto-resume timer if applicable
    if duration then
        manualOverrideActive = true
        manualOverrideDuration = duration
        manualOverrideKeybindTime = GetTime()
    elseif pauseTriggers[reason] and pauseTriggers[reason].autoResume then
        -- Auto-resume will be handled by Update function
    end
    
    -- Display pause status if enabled
    if showPauseStatus then
        local message = "Rotation paused: " .. reason
        if duration then
            message = message .. " for " .. duration .. " seconds"
        end
        API.PrintMessage(message)
    end
    
    API.PrintDebug("Rotation paused: " .. reason)
end

-- Resume the rotation
function RotationControlManager:ResumeRotation(reason)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Skip if not paused
    if not pauseRotation then
        return
    end
    
    -- Skip if trying to resume a different reason than what caused the pause
    if reason ~= currentPauseReason and reason ~= "MANUAL_COMMAND" and reason ~= "EXTERNAL" then
        return
    end
    
    -- Resume rotation
    pauseRotation = false
    currentPauseReason = ""
    pauseStartTime = 0
    manualOverrideActive = false
    
    -- Display resume status if enabled
    if showPauseStatus then
        API.PrintMessage("Rotation resumed")
    end
    
    API.PrintDebug("Rotation resumed: " .. reason)
end

-- Handle automatic resuming after delay
function RotationControlManager:HandleAutoResume(reason)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Skip if not paused or paused for different reason
    if not pauseRotation or currentPauseReason ~= reason then
        return
    end
    
    -- Skip if manual override is active
    if manualOverrideActive then
        return
    end
    
    -- Check if trigger allows auto resume
    if pauseTriggers[reason] and pauseTriggers[reason].autoResume then
        -- Record auto resume attempt time
        lastAutoResume = GetTime()
        
        -- Resume after delay
        local delay = pauseTriggers[reason].autoResumeDelay or 1.0
        C_Timer.After(delay, function()
            if currentPauseReason == reason then
                self:ResumeRotation(reason)
            end
        end)
    end
end

-- Check keybindings for manual pause/resume
function RotationControlManager:CheckKeybindings()
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Skip if no custom keybind
    if not customPauseKeybind then
        return
    end
    
    -- Check if keybind is pressed
    -- This would use a more sophisticated method in a real addon
    -- For now, this is a simplified placeholder
    local isPressed = false  -- Placeholder
    
    if isPressed then
        if pauseRotation then
            -- Keybind pressed while paused - resume
            self:ResumeRotation("MANUAL_KEYBIND")
        else
            -- Keybind pressed while not paused - pause
            self:PauseRotation("MANUAL_KEYBIND", customPauseDuration)
        end
    end
end

-- Handler for player movement input
function RotationControlManager:OnPlayerInput(inputType)
    -- Skip if control is disabled or not configured to pause on input
    if not controlEnabled or not pauseOnPlayerInput then
        return
    end
    
    -- Record input
    lastPlayerInput = GetTime()
    
    -- Add to history
    table.insert(playerInputHistory, {
        type = inputType,
        time = GetTime()
    })
    
    -- Trim history if it gets too long
    while #playerInputHistory > MAX_HISTORY_ENTRIES do
        table.remove(playerInputHistory, 1)
    end
    
    -- Pause rotation if not already paused
    if not pauseRotation then
        self:PauseRotation("PLAYER_INPUT")
    end
    
    -- Update auto-pause time
    lastAutoPause = GetTime()
end

-- Handler for player starting to cast a spell
function RotationControlManager:OnPlayerCastStart(spellID, castGUID)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Record cast
    castingTracking[castGUID] = {
        id = spellID,
        startTime = GetTime(),
        name = GetSpellInfo(spellID) or "Unknown Spell"
    }
    
    -- Check if it's an important spell
    if pauseOnImportantCasts and importantPlayerSpells[spellID] then
        self:PauseRotation("IMPORTANT_CAST")
        
        -- Record that this is an important cast
        castingTracking[castGUID].important = true
        castingTracking[castGUID].duration = importantPlayerSpells[spellID].duration
    end
    
    -- Count as player input
    self:OnPlayerInput("CAST")
end

-- Handler for player successfully casting a spell
function RotationControlManager:OnPlayerCastSucceeded(spellID, castGUID)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Update cast tracking
    if castingTracking[castGUID] then
        castingTracking[castGUID].succeeded = true
        castingTracking[castGUID].endTime = GetTime()
        
        -- If it was an important cast, update the pause duration
        if castingTracking[castGUID].important and castingTracking[castGUID].duration then
            local pauseDuration = castingTracking[castGUID].duration
            
            -- Extend pause duration for the important cast
            if pauseRotation and currentPauseReason == "IMPORTANT_CAST" then
                manualOverrideActive = true
                manualOverrideDuration = pauseDuration
                manualOverrideKeybindTime = GetTime()
            end
        end
    end
end

-- Handler for player stopping a cast
function RotationControlManager:OnPlayerCastStop(spellID, castGUID)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Update cast tracking
    if castingTracking[castGUID] then
        castingTracking[castGUID].stopped = true
        castingTracking[castGUID].endTime = GetTime()
        
        -- If it was an important cast and was successfully completed, handle it
        if castingTracking[castGUID].important and castingTracking[castGUID].succeeded then
            -- Keep the pause active for the duration
            -- This is handled in OnPlayerCastSucceeded
        else
            -- If the cast was interrupted/stopped, maybe we should resume sooner
            if pauseRotation and currentPauseReason == "IMPORTANT_CAST" then
                self:HandleAutoResume("IMPORTANT_CAST")
            end
        end
    end
end

-- Handler for player interrupting a cast
function RotationControlManager:OnPlayerCastInterrupted(spellID, castGUID)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Update cast tracking
    if castingTracking[castGUID] then
        castingTracking[castGUID].interrupted = true
        castingTracking[castGUID].endTime = GetTime()
        
        -- If an important cast was interrupted, handle it
        if castingTracking[castGUID].important then
            if pauseRotation and currentPauseReason == "IMPORTANT_CAST" then
                -- Resume rotation after a short delay
                self:HandleAutoResume("IMPORTANT_CAST")
            end
        end
    end
end

-- Handler for leaving combat
function RotationControlManager:OnLeaveCombat()
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Pause rotation when leaving combat if configured
    if pauseOutOfCombat and not pauseRotation then
        self:PauseRotation("OUT_OF_COMBAT")
    end
end

-- Handler for entering combat
function RotationControlManager:OnEnterCombat()
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Resume rotation if it was paused due to being out of combat
    if pauseRotation and currentPauseReason == "OUT_OF_COMBAT" then
        self:ResumeRotation("OUT_OF_COMBAT")
    end
}

-- Handler for UI panel being shown
function RotationControlManager:OnUIPanelShown(frameName)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Pause rotation when UI panel is shown
    if pauseOnUIPanels[frameName] and not pauseRotation then
        self:PauseRotation("USER_INTERFACE_OPEN")
    end
end

-- Handler for UI panel being hidden
function RotationControlManager:OnUIPanelHidden(frameName)
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Check if any other panels are still open
    local anyPanelOpen = false
    for panelName, _ in pairs(pauseOnUIPanels) do
        if _G[panelName] and _G[panelName]:IsShown() then
            anyPanelOpen = true
            break
        end
    end
    
    -- Resume rotation if no panels are open and we were paused due to UI
    if not anyPanelOpen and pauseRotation and currentPauseReason == "USER_INTERFACE_OPEN" then
        self:HandleAutoResume("USER_INTERFACE_OPEN")
    end
end

-- Update function to check for auto-resuming and manual override expiration
function RotationControlManager:Update()
    -- Skip if control is disabled
    if not controlEnabled then
        return
    end
    
    -- Check keybindings periodically
    if GetTime() - lastKeybindingCheck > KEYBINDING_CHECK_INTERVAL then
        self:CheckKeybindings()
        lastKeybindingCheck = GetTime()
    end
    
    -- Check if manual override should expire
    if manualOverrideActive and GetTime() - manualOverrideKeybindTime > manualOverrideDuration then
        manualOverrideActive = false
        
        -- Resume if still paused for the same reason
        if pauseRotation then
            self:ResumeRotation(currentPauseReason)
        end
    end
    
    -- Check for auto resume for player input
    if pauseRotation and currentPauseReason == "PLAYER_INPUT" and 
       not manualOverrideActive and 
       autoResumeAfterInput and
       GetTime() - lastPlayerInput > autoResumeDelay and
       GetTime() - lastAutoPause > MIN_AUTO_PAUSE_INTERVAL then
        -- Auto resume after delay
        self:HandleAutoResume("PLAYER_INPUT")
    end
}

-- Check if rotation is paused
function RotationControlManager.IsRotationPaused()
    return pauseRotation
end

-- Get current pause reason
function RotationControlManager.GetPauseReason()
    return currentPauseReason
end

-- Get pause duration
function RotationControlManager.GetPauseDuration()
    if pauseStartTime > 0 then
        return GetTime() - pauseStartTime
    else
        return 0
    end
end

-- Add a custom pause condition
function RotationControlManager:AddCustomPauseCondition(name, condition, autoResume, autoResumeDelay)
    customPauseConditions[name] = {
        condition = condition,
        autoResume = autoResume,
        autoResumeDelay = autoResumeDelay or 1.0
    }
}

-- Remove a custom pause condition
function RotationControlManager:RemoveCustomPauseCondition(name)
    customPauseConditions[name] = nil
end

-- Process rotation control based on combat state
function RotationControlManager.ProcessRotationControl(combatState)
    -- Skip if disabled
    if not controlEnabled then
        return false
    end
    
    -- Update state
    RotationControlManager:Update()
    
    -- Check custom pause conditions
    for name, condition in pairs(customPauseConditions) do
        if condition.condition(combatState) then
            -- Condition is met, pause rotation
            if not pauseRotation then
                RotationControlManager:PauseRotation(name)
            end
            break
        elseif pauseRotation and currentPauseReason == name then
            -- Condition is no longer met, maybe resume
            RotationControlManager:HandleAutoResume(name)
        end
    end
    
    -- Return pause state
    return pauseRotation
end

-- Return module
return RotationControlManager