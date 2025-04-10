local addonName, WR = ...

-- EncounterManager module for handling encounter-specific intelligence
local EncounterManager = {}
WR.EncounterManager = EncounterManager

-- Import constants
local CLASS, SPEC
if WR.ClassKnowledge then
    CLASS = WR.ClassKnowledge.CLASS
    SPEC = WR.ClassKnowledge.SPEC
end

-- Local variables
local currentClass, currentSpec
local inEncounter = false
local currentEncounter = nil
local currentPhase = 1
local currentMechanic = nil
local inMythicPlus = false
local knownMechanics = {}
local encounterId, encounterName, difficultyId, instanceType, instanceID
local encounterAdjustments = {}
local appliedAdjustments = {}

-- Constants
local MECHANIC_DETECTION_INTERVAL = 0.5  -- How often to check for active mechanics (seconds)
local RAID_TYPES = {
    ["party"] = "dungeon",
    ["raid"] = "raid",
    ["scenario"] = "scenario",
    ["none"] = "open_world"
}

-- Initialize the EncounterManager
function EncounterManager:Initialize()
    -- Import encounter data from ClassKnowledge if available
    if WR.ClassKnowledge and WR.ClassKnowledge.encounterAdjustments then
        encounterAdjustments = WR.ClassKnowledge.encounterAdjustments
    end
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("ENCOUNTER_START")
    eventFrame:RegisterEvent("ENCOUNTER_END")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("CHALLENGE_MODE_END")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            EncounterManager:DetectClassAndSpec()
            EncounterManager:ScanCurrentZone()
        elseif event == "ENCOUNTER_START" then
            local id, name, difficulty, groupSize = ...
            EncounterManager:OnEncounterStart(id, name, difficulty, groupSize)
        elseif event == "ENCOUNTER_END" then
            local id, name, difficulty, groupSize, success = ...
            EncounterManager:OnEncounterEnd(id, name, difficulty, groupSize, success)
        elseif event == "CHALLENGE_MODE_START" then
            EncounterManager:OnMythicPlusStart()
        elseif event == "CHALLENGE_MODE_END" then
            EncounterManager:OnMythicPlusEnd()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            EncounterManager:ScanCurrentZone()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            EncounterManager:ProcessCombatLog(CombatLogGetCurrentEventInfo())
        end
    end)
    
    -- Set up periodic mechanic detection
    C_Timer.NewTicker(MECHANIC_DETECTION_INTERVAL, function()
        if inEncounter then
            EncounterManager:DetectCurrentMechanic()
        end
    end)
    
    -- Initial detection
    self:DetectClassAndSpec()
    self:ScanCurrentZone()
    
    -- Integration with rotation enhancer
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RegisterEncounterManager(self)
    end
    
    WR:Debug("EncounterManager module initialized")
end

-- Detect player class and specialization
function EncounterManager:DetectClassAndSpec()
    currentClass = select(2, UnitClass("player"))
    currentSpec = GetSpecialization()
    
    WR:Debug("Detected class: " .. currentClass .. ", spec: " .. (currentSpec or "None"))
end

-- Scan current zone for dungeon/raid detection
function EncounterManager:ScanCurrentZone()
    local name, type, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID = GetInstanceInfo()
    
    instanceType = type
    difficultyId = difficultyID
    instanceID = mapID
    
    -- Reset encounter state when changing zones
    inEncounter = false
    currentEncounter = nil
    currentPhase = 1
    currentMechanic = nil
    
    -- Clear applied adjustments
    appliedAdjustments = {}
    
    -- Load zone-specific data
    self:LoadZoneData()
    
    WR:Debug("Zone detected: " .. name .. " (" .. type .. "), difficulty: " .. difficultyID .. ", map ID: " .. mapID)
}

-- Load zone-specific data
function EncounterManager:LoadZoneData()
    -- Check if we have data for this zone
    local zoneKey = self:GetZoneKey()
    
    if not zoneKey or not encounterAdjustments[zoneKey] then
        WR:Debug("No encounter data available for current zone")
        return
    end
    
    WR:Debug("Loaded encounter data for zone: " .. zoneKey)
}

-- Get current zone key for encounter data lookup
function EncounterManager:GetZoneKey()
    local name = GetInstanceInfo()
    
    -- Special handling for raids and dungeons
    if instanceType == "raid" then
        return name
    elseif instanceType == "party" then
        return name
    end
    
    return nil
}

-- Handle encounter start
function EncounterManager:OnEncounterStart(id, name, difficulty, groupSize)
    encounterId = id
    encounterName = name
    difficultyId = difficulty
    
    inEncounter = true
    currentEncounter = {
        id = id,
        name = name,
        difficulty = difficulty,
        groupSize = groupSize,
        startTime = GetTime(),
        phase = 1,
        mechanics = {}
    }
    
    currentPhase = 1
    currentMechanic = nil
    
    -- Load encounter-specific adjustments
    self:LoadEncounterAdjustments()
    
    -- Apply phase 1 adjustments
    self:ApplyPhaseAdjustments(1)
    
    WR:Debug("Encounter started: " .. name .. " (ID: " .. id .. ", Difficulty: " .. difficulty .. ")")
}

-- Handle encounter end
function EncounterManager:OnEncounterEnd(id, name, difficulty, groupSize, success)
    if success == 1 then
        WR:Debug("Encounter completed successfully: " .. name)
    else
        WR:Debug("Encounter failed: " .. name)
    end
    
    inEncounter = false
    
    -- Remove encounter-specific adjustments
    self:RemoveAllAdjustments()
    
    -- Reset encounter data
    currentEncounter = nil
    currentPhase = 1
    currentMechanic = nil
}

-- Handle Mythic+ start
function EncounterManager:OnMythicPlusStart()
    inMythicPlus = true
    
    WR:Debug("Mythic+ dungeon started")
}

-- Handle Mythic+ end
function EncounterManager:OnMythicPlusEnd()
    inMythicPlus = false
    
    WR:Debug("Mythic+ dungeon ended")
}

-- Process combat log events
function EncounterManager:ProcessCombatLog(...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags, spellID, spellName = ...
    
    -- Skip if not in an encounter
    if not inEncounter or not currentEncounter then
        return
    end
    
    -- Phase detection based on boss yells or specific spells
    self:DetectPhaseChange(event, sourceGUID, sourceName, spellID, spellName)
    
    -- Mechanic detection based on specific spells or debuffs
    self:DetectMechanicFromSpell(event, spellID, spellName, destGUID, destName)
}

-- Detect phase changes based on combat log events
function EncounterManager:DetectPhaseChange(event, sourceGUID, sourceName, spellID, spellName)
    if not currentEncounter then return end
    
    -- Get encounter data
    local zoneKey = self:GetZoneKey()
    local encounterData = encounterAdjustments[zoneKey] and encounterAdjustments[zoneKey][currentEncounter.id]
    
    if not encounterData or not encounterData.phase_detection then
        return
    end
    
    -- Check for phase change triggers
    local phaseDetection = encounterData.phase_detection
    
    for phase, triggers in pairs(phaseDetection) do
        -- Skip current phase
        if phase == currentPhase then
            goto continue
        end
        
        -- Check spell IDs
        if triggers.spell_ids and triggers.spell_ids[spellID] then
            self:SetPhase(phase)
            return
        end
        
        -- Check boss emotes/yells
        if event == "CHAT_MSG_MONSTER_YELL" or event == "CHAT_MSG_MONSTER_EMOTE" then
            if triggers.emotes then
                for _, emoteText in ipairs(triggers.emotes) do
                    if spellName and spellName:find(emoteText) then
                        self:SetPhase(phase)
                        return
                    end
                end
            end
        end
        
        -- Add more detection methods as needed
        
        ::continue::
    end
}

-- Set the current encounter phase
function EncounterManager:SetPhase(phase)
    if phase == currentPhase then return end
    
    local oldPhase = currentPhase
    currentPhase = phase
    
    -- Update encounter data
    if currentEncounter then
        currentEncounter.phase = phase
    end
    
    -- Remove adjustments from old phase
    self:RemovePhaseAdjustments(oldPhase)
    
    -- Apply adjustments for new phase
    self:ApplyPhaseAdjustments(phase)
    
    WR:Debug("Encounter phase changed: " .. oldPhase .. " -> " .. phase)
}

-- Detect mechanics from spells
function EncounterManager:DetectMechanicFromSpell(event, spellID, spellName, destGUID, destName)
    if not currentEncounter then return end
    
    -- Only process events targeting player or their group members
    if not destGUID then return end
    
    local isPlayer = (destGUID == UnitGUID("player"))
    local isPartyMember = IsInGroup() and UnitInParty(destName)
    
    if not isPlayer and not isPartyMember then return end
    
    -- Get encounter data
    local zoneKey = self:GetZoneKey()
    local encounterData = encounterAdjustments[zoneKey] and encounterAdjustments[zoneKey][currentEncounter.id]
    
    if not encounterData or not encounterData.phases or not encounterData.phases[currentPhase] then
        return
    end
    
    -- Check for recognized mechanics
    local phaseData = encounterData.phases[currentPhase]
    
    if not phaseData.mechanics then return end
    
    for mechanicName, mechanicData in pairs(phaseData.mechanics) do
        -- Check spell IDs for this mechanic
        if mechanicData.spell_ids and mechanicData.spell_ids[spellID] then
            self:SetActiveMechanic(mechanicName, mechanicData, isPlayer)
            return
        end
        
        -- Check debuff application
        if event == "SPELL_AURA_APPLIED" and mechanicData.debuff_ids and mechanicData.debuff_ids[spellID] then
            self:SetActiveMechanic(mechanicName, mechanicData, isPlayer)
            return
        end
    end
}

-- Detect current active mechanic
function EncounterManager:DetectCurrentMechanic()
    if not inEncounter or not currentEncounter then
        return
    end
    
    -- Get encounter data
    local zoneKey = self:GetZoneKey()
    local encounterData = encounterAdjustments[zoneKey] and encounterAdjustments[zoneKey][currentEncounter.id]
    
    if not encounterData or not encounterData.phases or not encounterData.phases[currentPhase] then
        return
    end
    
    -- Check for known mechanics in this phase
    local phaseData = encounterData.phases[currentPhase]
    
    if not phaseData.mechanics then return end
    
    for mechanicName, mechanicData in pairs(phaseData.mechanics) do
        -- Check mechanic detection conditions
        if self:IsMechanicActive(mechanicData) then
            self:SetActiveMechanic(mechanicName, mechanicData, true)
            return
        end
    end
    
    -- No active mechanic found, clear current
    if currentMechanic then
        self:ClearActiveMechanic()
    end
}

-- Check if a mechanic is active
function EncounterManager:IsMechanicActive(mechanicData)
    if not mechanicData then return false end
    
    -- Check for debuffs on player
    if mechanicData.debuff_ids then
        for debuffID, _ in pairs(mechanicData.debuff_ids) do
            if AuraUtil.FindAuraByName(GetSpellInfo(debuffID), "player") then
                return true
            end
        end
    end
    
    -- Check for ground effects (could be done via custom detection)
    if mechanicData.ground_effect and mechanicData.ground_effect_detection then
        -- This would be a custom implementation specific to the ground effect
        local detectionFunc = self[mechanicData.ground_effect_detection]
        if type(detectionFunc) == "function" then
            return detectionFunc(self)
        end
    end
    
    -- Add more detection methods as needed
    
    return false
}

-- Set active mechanic
function EncounterManager:SetActiveMechanic(mechanicName, mechanicData, isPlayer)
    -- Skip if already handling this mechanic
    if currentMechanic and currentMechanic.name == mechanicName then
        return
    end
    
    -- Store mechanic information
    currentMechanic = {
        name = mechanicName,
        data = mechanicData,
        startTime = GetTime(),
        affectsPlayer = isPlayer
    }
    
    -- Track mechanic for this encounter
    if currentEncounter then
        currentEncounter.mechanics[mechanicName] = (currentEncounter.mechanics[mechanicName] or 0) + 1
    end
    
    -- Apply mechanic-specific adjustments
    self:ApplyMechanicAdjustments(mechanicName, mechanicData)
    
    WR:Debug("Active mechanic detected: " .. mechanicName .. (isPlayer and " (affecting player)" or ""))
}

-- Clear active mechanic
function EncounterManager:ClearActiveMechanic()
    if not currentMechanic then return end
    
    -- Remove mechanic-specific adjustments
    self:RemoveMechanicAdjustments(currentMechanic.name)
    
    -- Clear current mechanic
    currentMechanic = nil
    
    WR:Debug("Active mechanic cleared")
}

-- Load encounter adjustments
function EncounterManager:LoadEncounterAdjustments()
    -- Reset applied adjustments
    appliedAdjustments = {}
    
    -- Get encounter data
    local zoneKey = self:GetZoneKey()
    local encounterData = encounterAdjustments[zoneKey] and encounterAdjustments[zoneKey][encounterId]
    
    if not encounterData then
        WR:Debug("No adjustments found for encounter: " .. (encounterName or "Unknown"))
        return
    end
    
    WR:Debug("Loaded adjustments for encounter: " .. (encounterName or "Unknown"))
}

-- Apply phase-specific adjustments
function EncounterManager:ApplyPhaseAdjustments(phase)
    -- Get encounter data
    local zoneKey = self:GetZoneKey()
    local encounterData = encounterAdjustments[zoneKey] and encounterAdjustments[zoneKey][encounterId]
    
    if not encounterData or not encounterData.phases or not encounterData.phases[phase] then
        return
    end
    
    local phaseData = encounterData.phases[phase]
    
    -- Apply general phase adjustments
    if phaseData.adjustments then
        self:ApplyAdjustments("phase_" .. phase, phaseData.adjustments)
    end
    
    WR:Debug("Applied phase " .. phase .. " adjustments")
}

-- Remove phase-specific adjustments
function EncounterManager:RemovePhaseAdjustments(phase)
    -- Remove adjustments for this phase
    self:RemoveAdjustments("phase_" .. phase)
    
    WR:Debug("Removed phase " .. phase .. " adjustments")
}

-- Apply mechanic-specific adjustments
function EncounterManager:ApplyMechanicAdjustments(mechanicName, mechanicData)
    if not mechanicData or not mechanicData.recommendations then
        return
    end
    
    -- Apply adjustments
    self:ApplyAdjustments("mechanic_" .. mechanicName, mechanicData.recommendations)
    
    WR:Debug("Applied " .. mechanicName .. " mechanic adjustments")
}

-- Remove mechanic-specific adjustments
function EncounterManager:RemoveMechanicAdjustments(mechanicName)
    -- Remove adjustments for this mechanic
    self:RemoveAdjustments("mechanic_" .. mechanicName)
    
    WR:Debug("Removed " .. mechanicName .. " mechanic adjustments")
}

-- Apply a set of adjustments
function EncounterManager:ApplyAdjustments(sourceKey, adjustments)
    if not adjustments then return end
    
    -- Store applied adjustments
    appliedAdjustments[sourceKey] = adjustments
    
    -- Apply to rotation system
    if WR.RotationEnhancer then
        WR.RotationEnhancer:ApplyEncounterAdjustments(sourceKey, adjustments)
    end
    
    -- Apply specific adjustments
    
    -- Cooldown holding
    if adjustments.cooldown_hold ~= nil and WR.Rotation then
        WR.Rotation:SetCooldownHold(adjustments.cooldown_hold)
    end
    
    -- Movement priority
    if adjustments.movement_priority ~= nil and WR.Rotation then
        WR.Rotation:SetMovementPriority(adjustments.movement_priority)
    end
    
    -- Defensive priority
    if adjustments.defensive_priority ~= nil and WR.Rotation then
        WR.Rotation:SetDefensivePriority(adjustments.defensive_priority)
    end
    
    -- Burst mode
    if adjustments.burst_priority ~= nil and WR.Rotation then
        WR.Rotation:SetBurstPriority(adjustments.burst_priority)
    end
    
    -- Priority ability adjustments
    if adjustments.priority_abilities and WR.Rotation then
        for spellID, factor in pairs(adjustments.priority_abilities) do
            WR.Rotation:AdjustSpellPriorityByID(spellID, factor)
        end
    end
    
    -- Add more adjustment types as needed
}

-- Remove a set of adjustments
function EncounterManager:RemoveAdjustments(sourceKey)
    local adjustments = appliedAdjustments[sourceKey]
    if not adjustments then return end
    
    -- Remove from rotation system
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RemoveEncounterAdjustments(sourceKey)
    end
    
    -- Revert specific adjustments
    
    -- Cooldown holding
    if adjustments.cooldown_hold ~= nil and WR.Rotation then
        WR.Rotation:SetCooldownHold(false) -- Default is false
    end
    
    -- Movement priority
    if adjustments.movement_priority ~= nil and WR.Rotation then
        WR.Rotation:SetMovementPriority(false) -- Default is false
    end
    
    -- Defensive priority
    if adjustments.defensive_priority ~= nil and WR.Rotation then
        WR.Rotation:SetDefensivePriority(false) -- Default is false
    end
    
    -- Burst mode
    if adjustments.burst_priority ~= nil and WR.Rotation then
        WR.Rotation:SetBurstPriority(false) -- Default is false
    end
    
    -- Priority ability adjustments
    if adjustments.priority_abilities and WR.Rotation then
        for spellID, _ in pairs(adjustments.priority_abilities) do
            WR.Rotation:ResetSpellPriorityByID(spellID)
        end
    end
    
    -- Clear from applied adjustments
    appliedAdjustments[sourceKey] = nil
}

-- Remove all encounter adjustments
function EncounterManager:RemoveAllAdjustments()
    -- Copy keys to prevent modification during iteration
    local keys = {}
    for k, _ in pairs(appliedAdjustments) do
        table.insert(keys, k)
    end
    
    -- Remove each adjustment set
    for _, key in ipairs(keys) do
        self:RemoveAdjustments(key)
    end
    
    -- Reset applied adjustments
    appliedAdjustments = {}
    
    WR:Debug("Removed all encounter adjustments")
}

-- Get current encounter status
function EncounterManager:GetEncounterStatus()
    if not inEncounter then
        return {
            active = false,
            instance_type = instanceType,
            difficulty = difficultyId,
            mythic_plus = inMythicPlus
        }
    end
    
    return {
        active = true,
        id = encounterId,
        name = encounterName,
        difficulty = difficultyId,
        phase = currentPhase,
        mechanic = currentMechanic and currentMechanic.name or nil,
        instance_type = instanceType,
        mythic_plus = inMythicPlus
    }
}

-- Check if in a specific encounter
function EncounterManager:IsInEncounter(id)
    return inEncounter and encounterId == id
}

-- Check if in a specific encounter phase
function EncounterManager:IsInPhase(phase)
    return inEncounter and currentPhase == phase
}

-- Check if a specific mechanic is active
function EncounterManager:IsMechanicActive(mechanicName)
    return currentMechanic and currentMechanic.name == mechanicName
}

-- Get all applied adjustments
function EncounterManager:GetAppliedAdjustments()
    return appliedAdjustments
}

-- Get available encounter data
function EncounterManager:GetAvailableEncounterData()
    local data = {}
    
    for zoneName, zoneData in pairs(encounterAdjustments) do
        local zoneInfo = {
            name = zoneName,
            encounters = {}
        }
        
        for encID, encData in pairs(zoneData) do
            table.insert(zoneInfo.encounters, {
                id = encID,
                name = encData.name or "Unknown",
                has_phases = encData.phases ~= nil,
                has_mechanics = self:HasMechanics(encData)
            })
        end
        
        table.insert(data, zoneInfo)
    end
    
    return data
end

-- Check if encounter data has mechanics
function EncounterManager:HasMechanics(encounterData)
    if not encounterData or not encounterData.phases then
        return false
    end
    
    for _, phaseData in pairs(encounterData.phases) do
        if phaseData.mechanics and next(phaseData.mechanics) then
            return true
        end
    end
    
    return false
end

-- Force a check for active mechanics
function EncounterManager:ForceCheckMechanics()
    self:DetectCurrentMechanic()
}

-- Create encounter intelligence UI
function EncounterManager:CreateEncounterUI(parent)
    if not parent then return end
    
    -- Create the frame
    local frame = CreateFrame("Frame", "WindrunnerRotationsEncounterUI", parent, "BackdropTemplate")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Create title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Encounter Intelligence")
    
    -- Create close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Create tab buttons
    local tabWidth = 120
    local tabHeight = 24
    local tabs = {}
    local tabContents = {}
    
    local tabNames = {"Current", "Adjustments", "Database"}
    
    for i, tabName in ipairs(tabNames) do
        -- Create tab button
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20 + (i-1) * (tabWidth + 5), -40)
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tabText:SetText(tabName)
        
        -- Create highlight texture
        local highlightTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        highlightTexture:SetAllPoints()
        highlightTexture:SetColorTexture(1, 1, 1, 0.2)
        
        -- Create selected texture
        local selectedTexture = tab:CreateTexture(nil, "BACKGROUND")
        selectedTexture:SetAllPoints()
        selectedTexture:SetColorTexture(0.2, 0.4, 0.8, 0.2)
        selectedTexture:Hide()
        tab.selectedTexture = selectedTexture
        
        -- Create tab content frame
        local content = CreateFrame("Frame", nil, frame)
        content:SetSize(frame:GetWidth() - 40, frame:GetHeight() - 80)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -70)
        content:Hide()
        
        -- Set up tab behavior
        tab:SetScript("OnClick", function()
            -- Hide all contents
            for _, contentFrame in ipairs(tabContents) do
                contentFrame:Hide()
            end
            
            -- Show this content
            content:Show()
            
            -- Update tab appearance
            for _, tabButton in ipairs(tabs) do
                tabButton.selectedTexture:Hide()
            end
            
            tab.selectedTexture:Show()
            
            -- Update content
            if tabName == "Current" then
                EncounterManager:UpdateCurrentTab(content)
            elseif tabName == "Adjustments" then
                EncounterManager:UpdateAdjustmentsTab(content)
            elseif tabName == "Database" then
                EncounterManager:UpdateDatabaseTab(content)
            end
        end)
        
        tabs[i] = tab
        tabContents[i] = content
    end
    
    -- Function to update current tab
    function EncounterManager:UpdateCurrentTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Status section
        local statusFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        statusFrame:SetSize(content:GetWidth(), 120)
        statusFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        statusFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        statusFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        
        -- Add refresh button
        local refreshButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        refreshButton:SetSize(100, 24)
        refreshButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
        refreshButton:SetText("Refresh")
        refreshButton:SetScript("OnClick", function()
            EncounterManager:UpdateCurrentTab(content)
        end)
        
        -- Get current status
        local status = self:GetEncounterStatus()
        
        -- Status title
        local statusTitle = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusTitle:SetPoint("TOPLEFT", statusFrame, "TOPLEFT", 15, -15)
        statusTitle:SetText("Current Status")
        
        -- Instance type
        local instanceText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        instanceText:SetPoint("TOPLEFT", statusTitle, "BOTTOMLEFT", 10, -10)
        
        local instanceTypeName = RAID_TYPES[status.instance_type] or status.instance_type or "Unknown"
        if status.mythic_plus then
            instanceTypeName = "Mythic+ Dungeon"
        end
        
        instanceText:SetText("Instance Type: " .. instanceTypeName)
        
        -- Difficulty
        local difficultyText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        difficultyText:SetPoint("TOPLEFT", instanceText, "BOTTOMLEFT", 0, -5)
        
        local difficultyName = status.difficulty and GetDifficultyInfo(status.difficulty) or "Unknown"
        difficultyText:SetText("Difficulty: " .. difficultyName)
        
        -- Encounter status
        local encounterText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        encounterText:SetPoint("TOPLEFT", difficultyText, "BOTTOMLEFT", 0, -5)
        
        if status.active then
            encounterText:SetText("Encounter: " .. (status.name or "Unknown") .. " (Phase " .. status.phase .. ")")
            
            -- Active mechanic
            local mechanicText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            mechanicText:SetPoint("TOPLEFT", encounterText, "BOTTOMLEFT", 0, -5)
            
            if status.mechanic then
                mechanicText:SetText("Active Mechanic: " .. status.mechanic)
            else
                mechanicText:SetText("Active Mechanic: None")
            end
        else
            encounterText:SetText("Encounter: None")
        end
        
        -- Active adjustments section (if in encounter)
        if status.active then
            local adjustmentsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
            adjustmentsFrame:SetSize(content:GetWidth(), content:GetHeight() - 130)
            adjustmentsFrame:SetPoint("TOPLEFT", statusFrame, "BOTTOMLEFT", 0, -10)
            adjustmentsFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            adjustmentsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Create scroll frame for adjustments
            local scrollFrame = CreateFrame("ScrollFrame", nil, adjustmentsFrame, "UIPanelScrollFrameTemplate")
            scrollFrame:SetSize(adjustmentsFrame:GetWidth() - 30, adjustmentsFrame:GetHeight() - 30)
            scrollFrame:SetPoint("TOPLEFT", adjustmentsFrame, "TOPLEFT", 10, -10)
            
            local scrollChild = CreateFrame("Frame", nil, scrollFrame)
            scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
            scrollFrame:SetScrollChild(scrollChild)
            
            -- Active adjustments title
            local adjustmentsTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            adjustmentsTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, 0)
            adjustmentsTitle:SetText("Active Adjustments")
            
            -- List active adjustments
            local y = -30
            local hasAdjustments = false
            
            for sourceKey, adjustments in pairs(appliedAdjustments) do
                hasAdjustments = true
                
                local sourceText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                sourceText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
                sourceText:SetText("Source: " .. sourceKey)
                
                y = y - 20
                
                -- List adjustments
                for adjustType, value in pairs(adjustments) do
                    if type(value) ~= "table" then
                        local adjustText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        adjustText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
                        adjustText:SetText("- " .. adjustType .. ": " .. tostring(value))
                        
                        y = y - 15
                    elseif adjustType == "priority_abilities" then
                        local headerText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        headerText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, y)
                        headerText:SetText("- Priority ability adjustments:")
                        
                        y = y - 15
                        
                        for spellID, factor in pairs(value) do
                            local spellName = GetSpellInfo(spellID) or "Unknown"
                            local spellText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            spellText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, y)
                            spellText:SetText("  " .. spellName .. " (ID: " .. spellID .. "): x" .. tostring(factor))
                            
                            y = y - 15
                        end
                    end
                end
                
                y = y - 10
            end
            
            if not hasAdjustments then
                local noAdjustmentsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                noAdjustmentsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
                noAdjustmentsText:SetText("No active adjustments")
                
                y = y - 20
            end
            
            -- Set scroll child height
            scrollChild:SetHeight(math.abs(y) + 20)
        end
    end
    
    -- Function to update adjustments tab
    function EncounterManager:UpdateAdjustmentsTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Title
        local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        title:SetText("Encounter Adjustments")
        
        local y = -30
        
        -- Get current status
        local status = self:GetEncounterStatus()
        
        if not status.active then
            local notActiveText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            notActiveText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            notActiveText:SetText("No active encounter")
            
            scrollChild:SetHeight(50)
            return
        end
        
        -- Get encounter data
        local zoneKey = self:GetZoneKey()
        local encounterData = encounterAdjustments[zoneKey] and encounterAdjustments[zoneKey][encounterId]
        
        if not encounterData then
            local noDataText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noDataText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            noDataText:SetText("No adjustment data available for " .. (encounterName or "this encounter"))
            
            scrollChild:SetHeight(50)
            return
        end
        
        -- Encounter info
        local encounterNameText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        encounterNameText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
        encounterNameText:SetText("Encounter: " .. (encounterName or "Unknown") .. " (ID: " .. encounterId .. ")")
        
        y = y - 25
        
        -- Phase adjustments section
        if encounterData.phases then
            local phaseTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            phaseTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            phaseTitle:SetText("Phase Adjustments:")
            
            y = y - 20
            
            for phase, phaseData in pairs(encounterData.phases) do
                local phaseFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
                phaseFrame:SetSize(scrollChild:GetWidth() - 20, 100) -- Height will be adjusted
                phaseFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
                phaseFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                phaseFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                -- Highlight current phase
                if phase == currentPhase then
                    phaseFrame:SetBackdropBorderColor(0, 1, 0)
                end
                
                -- Phase header
                local phaseText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                phaseText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 15, -15)
                phaseText:SetText("Phase " .. phase .. (phase == currentPhase and " (Current)" or ""))
                
                local phaseY = -40
                
                -- Phase adjustments
                if phaseData.adjustments then
                    local adjustmentsText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    adjustmentsText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 20, phaseY)
                    adjustmentsText:SetText("Adjustments:")
                    
                    phaseY = phaseY - 20
                    
                    for adjustType, value in pairs(phaseData.adjustments) do
                        if type(value) ~= "table" then
                            local adjustText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            adjustText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 25, phaseY)
                            adjustText:SetText("- " .. adjustType .. ": " .. tostring(value))
                            
                            phaseY = phaseY - 15
                        elseif adjustType == "priority_abilities" then
                            local headerText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            headerText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 25, phaseY)
                            headerText:SetText("- Priority ability adjustments:")
                            
                            phaseY = phaseY - 15
                            
                            for spellID, factor in pairs(value) do
                                local spellName = GetSpellInfo(spellID) or "Unknown"
                                local spellText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                                spellText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 30, phaseY)
                                spellText:SetText("  " .. spellName .. " (ID: " .. spellID .. "): x" .. tostring(factor))
                                
                                phaseY = phaseY - 15
                            end
                        end
                    end
                else
                    local noAdjustmentsText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    noAdjustmentsText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 20, phaseY)
                    noAdjustmentsText:SetText("No general phase adjustments")
                    
                    phaseY = phaseY - 20
                end
                
                -- Mechanics in this phase
                if phaseData.mechanics and next(phaseData.mechanics) then
                    phaseY = phaseY - 10
                    
                    local mechanicsText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    mechanicsText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 20, phaseY)
                    mechanicsText:SetText("Mechanics:")
                    
                    phaseY = phaseY - 20
                    
                    for mechanicName, mechanicData in pairs(phaseData.mechanics) do
                        local isActive = currentMechanic and currentMechanic.name == mechanicName
                        
                        local mechanicText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        mechanicText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 25, phaseY)
                        mechanicText:SetText("- " .. mechanicName .. (isActive and " (Active)" or ""))
                        
                        -- Highlight active mechanic
                        if isActive then
                            mechanicText:SetTextColor(0, 1, 0)
                        end
                        
                        phaseY = phaseY - 15
                        
                        -- Mechanic adjustments
                        if mechanicData.recommendations then
                            for adjustType, value in pairs(mechanicData.recommendations) do
                                if type(value) ~= "table" and adjustType ~= "description" then
                                    local adjustText = phaseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                                    adjustText:SetPoint("TOPLEFT", phaseFrame, "TOPLEFT", 30, phaseY)
                                    adjustText:SetText("  " .. adjustType .. ": " .. tostring(value))
                                    
                                    phaseY = phaseY - 15
                                end
                            end
                        end
                    end
                end
                
                -- Set frame height
                phaseFrame:SetHeight(math.abs(phaseY) + 20)
                
                y = y - phaseFrame:GetHeight() - 10
            }
        } else {
            local noPhaseText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noPhaseText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            noPhaseText:SetText("No phase data available for this encounter")
            
            y = y - 20
        }
        
        -- Set scroll child height
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Function to update database tab
    function EncounterManager:UpdateDatabaseTab(content)
        -- Clear existing content
        for i = content:GetNumChildren(), 1, -1 do
            local child = select(i, content:GetChildren())
            child:Hide()
            child:SetParent(nil)
        end
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, content, "UIPanelScrollFrameTemplate")
        scrollFrame:SetSize(content:GetWidth() - 30, content:GetHeight())
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Title
        local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, 0)
        title:SetText("Encounter Database")
        
        local y = -30
        
        -- Get encounter data
        local encounterData = self:GetAvailableEncounterData()
        
        if #encounterData == 0 then
            local noDataText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noDataText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            noDataText:SetText("No encounter data available")
            
            scrollChild:SetHeight(50)
            return
        end
        
        -- List zones and encounters
        for _, zoneInfo in ipairs(encounterData) do
            local zoneFrame = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            zoneFrame:SetSize(scrollChild:GetWidth() - 20, 50) -- Height will be adjusted
            zoneFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
            zoneFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            zoneFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            
            -- Zone header
            local zoneText = zoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            zoneText:SetPoint("TOPLEFT", zoneFrame, "TOPLEFT", 15, -15)
            zoneText:SetText(zoneInfo.name)
            
            local zoneY = -40
            
            -- List encounters
            if #zoneInfo.encounters > 0 then
                for _, encounter in ipairs(zoneInfo.encounters) do
                    local encounterText = zoneFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    encounterText:SetPoint("TOPLEFT", zoneFrame, "TOPLEFT", 20, zoneY)
                    
                    local encounterDesc = encounter.name
                    if encounter.has_phases then
                        encounterDesc = encounterDesc .. " (Has phases"
                        if encounter.has_mechanics then
                            encounterDesc = encounterDesc .. ", Has mechanics)"
                        else
                            encounterDesc = encounterDesc .. ")"
                        end
                    elseif encounter.has_mechanics then
                        encounterDesc = encounterDesc .. " (Has mechanics)"
                    end
                    
                    encounterText:SetText("- " .. encounterDesc)
                    
                    zoneY = zoneY - 20
                }
            } else {
                local noEncountersText = zoneFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                noEncountersText:SetPoint("TOPLEFT", zoneFrame, "TOPLEFT", 20, zoneY)
                noEncountersText:SetText("No encounters defined")
                
                zoneY = zoneY - 20
            }
            
            -- Set frame height
            zoneFrame:SetHeight(math.abs(zoneY) + 20)
            
            y = y - zoneFrame:GetHeight() - 10
        }
        
        -- Set scroll child height
        scrollChild:SetHeight(math.abs(y) + 20)
    end
    
    -- Select first tab by default
    tabs[1].selectedTexture:Show()
    tabContents[1]:Show()
    
    -- Update first tab content
    EncounterManager:UpdateCurrentTab(tabContents[1])
    
    -- Hide by default
    frame:Hide()
    
    return frame
end

-- Initialize the module
EncounterManager:Initialize()

return EncounterManager