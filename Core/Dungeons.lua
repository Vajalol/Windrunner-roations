local addonName, WR = ...

-- Dungeons module - handles dungeon and encounter detection
local Dungeons = {}
WR.Dungeons = Dungeons

-- State
local state = {
    currentDungeonID = nil,
    currentDungeonName = nil,
    inDungeon = false,
    inMythicPlus = false,
    mythicPlusLevel = 0,
    currentAffixes = {},
    currentEncounter = nil,
    encounterActive = false,
    bossesDefeated = {},
    timerStart = 0,
    timerEnd = 0,
    lastCheckTime = 0,
    checkInterval = 1.0, -- Check dungeon state every second
}

-- Initialize the dungeons module
function Dungeons:Initialize()
    -- Create a frame for events
    local frame = CreateFrame("Frame")
    
    -- Register for dungeon and encounter events
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ENCOUNTER_START")
    frame:RegisterEvent("ENCOUNTER_END")
    frame:RegisterEvent("CHALLENGE_MODE_START")
    frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    frame:RegisterEvent("CHALLENGE_MODE_RESET")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            Dungeons:CheckCurrentDungeon()
        elseif event == "ENCOUNTER_START" then
            Dungeons:ENCOUNTER_START(...)
        elseif event == "ENCOUNTER_END" then
            Dungeons:ENCOUNTER_END(...)
        elseif event == "CHALLENGE_MODE_START" then
            Dungeons:CHALLENGE_MODE_START(...)
        elseif event == "CHALLENGE_MODE_COMPLETED" then
            Dungeons:CHALLENGE_MODE_COMPLETED(...)
        elseif event == "CHALLENGE_MODE_RESET" then
            Dungeons:CHALLENGE_MODE_RESET(...)
        end
    end)
    
    -- Create OnUpdate handler for periodic checks
    frame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        if now - state.lastCheckTime >= state.checkInterval then
            state.lastCheckTime = now
            Dungeons:CheckCurrentDungeon()
        end
    end)
    
    WR:Debug("Dungeons module initialized")
}

-- Check the current dungeon
function Dungeons:CheckCurrentDungeon()
    -- Get instance info
    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
    
    -- Check if we're in a dungeon
    local inDungeon = instanceType == "party"
    
    -- If dungeon status changed
    if inDungeon ~= state.inDungeon or instanceID ~= state.currentDungeonID then
        state.inDungeon = inDungeon
        state.currentDungeonID = instanceID
        state.currentDungeonName = name
        
        -- Reset dungeon state
        state.currentEncounter = nil
        state.encounterActive = false
        wipe(state.bossesDefeated)
        
        -- Check if we're in a M+ dungeon
        state.inMythicPlus = (difficultyID == 8) -- Mythic Keystone
        state.mythicPlusLevel = 0
        wipe(state.currentAffixes)
        
        if state.inMythicPlus then
            local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(instanceID)
            state.timeLimit = timeLimit
            
            -- Get current M+ level
            state.mythicPlusLevel = C_ChallengeMode.GetActiveKeystoneInfo()
            
            -- Get current affixes
            local affixes = C_MythicPlus.GetCurrentAffixes()
            if affixes then
                for _, affixTable in ipairs(affixes) do
                    local affixID = affixTable.id
                    local name = C_ChallengeMode.GetAffixInfo(affixID)
                    table.insert(state.currentAffixes, {
                        id = affixID,
                        name = name
                    })
                end
            end
        end
        
        if inDungeon then
            WR:Debug("Entered dungeon:", name, "(ID:", instanceID, ")")
            if state.inMythicPlus then
                WR:Debug("Mythic+ level:", state.mythicPlusLevel)
                for _, affix in ipairs(state.currentAffixes) do
                    WR:Debug("Affix:", affix.name, "(ID:", affix.id, ")")
                end
            end
        else
            WR:Debug("Left dungeon")
        end
        
        -- Load dungeon-specific data
        self:LoadDungeonData()
    end
}

-- Load specific data for the current dungeon
function Dungeons:LoadDungeonData()
    if not state.inDungeon or not state.currentDungeonID then
        return
    end
    
    -- Look up dungeon data from our database
    local dungeonData = WR.Data.Dungeons[state.currentDungeonID]
    if not dungeonData then
        WR:Debug("No data for dungeon:", state.currentDungeonName, "(ID:", state.currentDungeonID, ")")
        return
    end
    
    -- Store dungeon data for use
    state.dungeonData = dungeonData
    
    WR:Debug("Loaded data for dungeon:", state.currentDungeonName)
}

-- Handle encounter start event
function Dungeons:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
    state.currentEncounter = {
        id = encounterID,
        name = encounterName,
        difficultyID = difficultyID,
        groupSize = groupSize,
        startTime = GetTime()
    }
    
    state.encounterActive = true
    
    -- Look up encounter-specific data
    local encounterData = nil
    if state.dungeonData and state.dungeonData.encounters then
        for _, encounter in ipairs(state.dungeonData.encounters) do
            if encounter.id == encounterID then
                encounterData = encounter
                break
            end
        end
    end
    
    state.currentEncounterData = encounterData
    
    WR:Debug("Encounter started:", encounterName, "(ID:", encounterID, ")")
    
    -- Apply encounter-specific rotation settings
    if encounterData and encounterData.rotationSettings then
        self:ApplyEncounterSettings(encounterData.rotationSettings)
    end
}

-- Handle encounter end event
function Dungeons:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
    if state.currentEncounter and state.currentEncounter.id == encounterID then
        state.currentEncounter.endTime = GetTime()
        state.currentEncounter.success = success == 1
        state.currentEncounter.duration = state.currentEncounter.endTime - state.currentEncounter.startTime
        
        if success == 1 then
            table.insert(state.bossesDefeated, encounterID)
            WR:Debug("Encounter completed:", encounterName, "in", string.format("%.2f", state.currentEncounter.duration), "seconds")
        else
            WR:Debug("Encounter failed:", encounterName)
        end
    end
    
    state.encounterActive = false
    state.currentEncounterData = nil
    
    -- Restore default rotation settings
    self:RestoreDefaultSettings()
}

-- Handle Mythic+ start event
function Dungeons:CHALLENGE_MODE_START()
    state.timerStart = GetTime()
    WR:Debug("Mythic+ started")
}

-- Handle Mythic+ completion event
function Dungeons:CHALLENGE_MODE_COMPLETED()
    state.timerEnd = GetTime()
    local duration = state.timerEnd - state.timerStart
    
    WR:Debug("Mythic+ completed in", string.format("%.2f", duration), "seconds")
}

-- Handle Mythic+ reset event
function Dungeons:CHALLENGE_MODE_RESET()
    state.timerStart = 0
    state.timerEnd = 0
    wipe(state.bossesDefeated)
    
    WR:Debug("Mythic+ reset")
}

-- Apply encounter-specific rotation settings
function Dungeons:ApplyEncounterSettings(settings)
    if not settings then return end
    
    -- Store the original settings to restore later
    if not state.originalSettings then
        state.originalSettings = {
            enableInterrupts = WR.Config:Get("enableInterrupts"),
            enableDefensives = WR.Config:Get("enableDefensives"),
            enableCooldowns = WR.Config:Get("enableCooldowns"),
            enableAOE = WR.Config:Get("enableAOE"),
        }
    end
    
    -- Apply the encounter-specific settings
    if settings.enableInterrupts ~= nil then
        WR.Config:Set("enableInterrupts", settings.enableInterrupts)
    end
    
    if settings.enableDefensives ~= nil then
        WR.Config:Set("enableDefensives", settings.enableDefensives)
    end
    
    if settings.enableCooldowns ~= nil then
        WR.Config:Set("enableCooldowns", settings.enableCooldowns)
    end
    
    if settings.enableAOE ~= nil then
        WR.Config:Set("enableAOE", settings.enableAOE)
    end
    
    WR:Debug("Applied encounter-specific rotation settings")
}

-- Restore default rotation settings
function Dungeons:RestoreDefaultSettings()
    if not state.originalSettings then return end
    
    -- Restore the original settings
    WR.Config:Set("enableInterrupts", state.originalSettings.enableInterrupts)
    WR.Config:Set("enableDefensives", state.originalSettings.enableDefensives)
    WR.Config:Set("enableCooldowns", state.originalSettings.enableCooldowns)
    WR.Config:Set("enableAOE", state.originalSettings.enableAOE)
    
    state.originalSettings = nil
    
    WR:Debug("Restored default rotation settings")
}

-- Get current dungeon info
function Dungeons:GetCurrentDungeon()
    return {
        inDungeon = state.inDungeon,
        id = state.currentDungeonID,
        name = state.currentDungeonName,
        inMythicPlus = state.inMythicPlus,
        mythicPlusLevel = state.mythicPlusLevel,
        affixes = state.currentAffixes,
        timeLimit = state.timeLimit,
        timerStart = state.timerStart,
        elapsedTime = (state.timerStart > 0) and (GetTime() - state.timerStart) or 0,
        bossesDefeated = #state.bossesDefeated
    }
end

-- Get current encounter info
function Dungeons:GetCurrentEncounter()
    if not state.encounterActive then
        return nil
    end
    
    return {
        active = state.encounterActive,
        id = state.currentEncounter.id,
        name = state.currentEncounter.name,
        startTime = state.currentEncounter.startTime,
        elapsedTime = GetTime() - state.currentEncounter.startTime,
        data = state.currentEncounterData
    }
end

-- Check if a specific rotation behavior should be enabled based on dungeon/encounter
function Dungeons:ShouldEnableBehavior(behaviorType)
    -- If dungeon awareness is disabled in settings, use default behavior
    if not WR.Config:Get("enableDungeonAwareness") then
        return nil -- nil means "use default settings"
    end
    
    -- If we're in an encounter with specific settings
    if state.encounterActive and state.currentEncounterData then
        if state.currentEncounterData.rotationSettings and 
           state.currentEncounterData.rotationSettings[behaviorType] ~= nil then
            return state.currentEncounterData.rotationSettings[behaviorType]
        end
    end
    
    -- If we're in a dungeon with specific settings
    if state.inDungeon and state.dungeonData then
        if state.dungeonData.rotationSettings and 
           state.dungeonData.rotationSettings[behaviorType] ~= nil then
            return state.dungeonData.rotationSettings[behaviorType]
        end
    end
    
    return nil -- Use default settings
}

-- Check if we should use special interrupt priorities
function Dungeons:GetInterruptPriorities()
    -- If not in a dungeon or dungeon awareness disabled, return nil
    if not state.inDungeon or not WR.Config:Get("enableDungeonAwareness") then
        return nil
    end
    
    -- If in an encounter, check for encounter-specific interrupt priorities
    if state.encounterActive and state.currentEncounterData and state.currentEncounterData.interruptPriorities then
        return state.currentEncounterData.interruptPriorities
    end
    
    -- Otherwise check for dungeon-wide interrupt priorities
    if state.dungeonData and state.dungeonData.interruptPriorities then
        return state.dungeonData.interruptPriorities
    end
    
    return nil
}

-- Get the time remaining in the M+ dungeon
function Dungeons:GetTimeRemaining()
    if not state.inMythicPlus or state.timerStart == 0 or not state.timeLimit then
        return nil
    end
    
    local elapsed = GetTime() - state.timerStart
    local remaining = state.timeLimit - elapsed
    
    return remaining
}

-- Check if we're in time in the M+ dungeon
function Dungeons:IsInTime()
    local remaining = self:GetTimeRemaining()
    return remaining and remaining > 0
end
