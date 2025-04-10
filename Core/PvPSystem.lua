local addonName, WR = ...

-- PvPSystem module for handling PvP-specific rotation and ability optimizations
local PvPSystem = {}
WR.PvPSystem = PvPSystem

-- Local variables
local inPvP = false
local inArena = false
local inBattleground = false
local enemyPlayers = {}
local friendlyPlayers = {}
local targetDR = {}
local enemyRoles = { healers = {}, damageDealers = {}, tanks = {} }
local enemyCooldowns = {}
local enemyDRs = {}
local inBurstWindow = false
local defensiveNeedLevel = 0 -- 0-3 scale of defensive urgency
local targetSwitchTarget = nil
local ccTarget = nil
local targetPriority = {}
local playerDefensiveCooldowns = {}
local playerOffensiveCooldowns = {}
local playerCCAbilities = {}
local currentClass, currentSpec

-- Settings
local settings = {
    enablePvPOptimization = true,
    prioritizeHealers = true,      -- Prioritize enemy healers as targets
    autoDefensiveUsage = true,     -- Auto-suggest defensives when in danger
    showEnemyCooldowns = true,     -- Display tracked enemy cooldowns
    showDiminishingReturns = true, -- Show DR status on enemies
    autoInterrupt = true,          -- Prioritize interrupts for important casts
    enableBurstDetection = true,   -- Detect and respond to burst windows
    targetSwitchSuggestions = true, -- Suggest target switches
    enableFocusTargeting = true,   -- Enable focus target system
    showPvPTeamDisplay = true      -- Show team/enemy status display in arena
}

-- Constants for CC categories
local DR_CATEGORIES = {
    STUN = "stun",
    INCAPACITATE = "incapacitate",
    SILENCE = "silence",
    DISARM = "disarm",
    ROOT = "root",
    DISORIENT = "disorient"
}

-- DR diminishment levels
local DR_LEVELS = {
    [0] = 1.0,    -- No DR
    [1] = 0.5,    -- 50% duration
    [2] = 0.25,   -- 25% duration
    [3] = 0.0     -- Immune
}

-- Tables for ability categorization
local ccAbilities = {}  -- Will be populated based on class
local interruptAbilities = {}
local defensiveAbilities = {}
local offensiveAbilities = {}

-- Initialize the PvPSystem
function PvPSystem:Initialize()
    -- Get player class and spec
    self:UpdatePlayerInfo()
    
    -- Load saved data
    self:LoadSavedData()
    
    -- Register events
    self:RegisterEvents()
    
    -- Set up ability mappings
    self:InitializeAbilityMappings()
    
    -- Create UI if enabled
    if settings.showPvPTeamDisplay then
        self:InitializeUI()
    end
    
    -- Initialize profiles
    self:LoadPvPProfiles()
    
    -- Register with rotation enhancer
    self:RegisterWithRotationEnhancer()
    
    WR:Debug("PvPSystem module initialized")
end

-- Update player information
function PvPSystem:UpdatePlayerInfo()
    currentClass = select(2, UnitClass("player"))
    currentSpec = GetSpecialization()
    
    -- Clear cooldown trackers as they depend on class/spec
    playerDefensiveCooldowns = {}
    playerOffensiveCooldowns = {}
    playerCCAbilities = {}
    
    -- Populate trackers with class/spec specific abilities
    self:PopulatePlayerAbilities()
    
    WR:Debug("PvPSystem: Updated player info - " .. currentClass .. " " .. (currentSpec or "Unknown"))
end

-- Load saved data
function PvPSystem:LoadSavedData()
    if WindrunnerRotationsDB and WindrunnerRotationsDB.PvPSystem then
        -- Load settings
        if WindrunnerRotationsDB.PvPSystem.settings then
            for k, v in pairs(WindrunnerRotationsDB.PvPSystem.settings) do
                if settings[k] ~= nil then
                    settings[k] = v
                end
            end
        end
    end
    
    WR:Debug("PvPSystem: Loaded saved data")
end

-- Save data
function PvPSystem:SaveData()
    -- Initialize storage if needed
    WindrunnerRotationsDB = WindrunnerRotationsDB or {}
    WindrunnerRotationsDB.PvPSystem = WindrunnerRotationsDB.PvPSystem or {}
    
    -- Save settings
    WindrunnerRotationsDB.PvPSystem.settings = CopyTable(settings)
    
    WR:Debug("PvPSystem: Saved data")
end

-- Register events
function PvPSystem:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            PvPSystem:CheckPvPStatus()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
            PvPSystem:UpdatePlayerInfo()
        elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
            PvPSystem:ProcessArenaOpponents()
        elseif event == "ARENA_OPPONENT_UPDATE" then
            local unit, updateType = ...
            PvPSystem:UpdateArenaOpponent(unit, updateType)
        elseif event == "UNIT_AURA" then
            local unit = ...
            PvPSystem:ProcessAuras(unit)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            PvPSystem:ProcessCombatLog(CombatLogGetCurrentEventInfo())
        elseif event == "UNIT_SPELLCAST_START" then
            local unit, _, spellID = ...
            PvPSystem:ProcessSpellCastStart(unit, spellID)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            PvPSystem:ProcessSpellCastSuccess(unit, spellID)
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            PvPSystem:ProcessHealthUpdate(unit)
        elseif event == "GROUP_ROSTER_UPDATE" then
            PvPSystem:UpdateGroupMembers()
        end
    end)
end

-- Initialize ability mappings for various categories
function PvPSystem:InitializeAbilityMappings()
    -- Interrupt abilities by class
    interruptAbilities = {
        WARRIOR = {6552},    -- Pummel
        PALADIN = {96231},   -- Rebuke
        HUNTER = {147362},   -- Counter Shot
        ROGUE = {1766},      -- Kick
        PRIEST = {15487},    -- Silence (Shadow)
        DEATHKNIGHT = {47528}, -- Mind Freeze
        SHAMAN = {57994},    -- Wind Shear
        MAGE = {2139},       -- Counterspell
        WARLOCK = {19647},   -- Spell Lock (pet)
        MONK = {116705},     -- Spear Hand Strike
        DRUID = {106839},    -- Skull Bash
        DEMONHUNTER = {183752}, -- Disrupt
        EVOKER = {351338}    -- Quell
    }
    
    -- CC abilities will be populated by class in PopulatePlayerAbilities
    
    -- DR categories by spell ID - simplified for demonstration
    -- In a real implementation, this would be a comprehensive list
    ccAbilities = {
        [119381] = DR_CATEGORIES.STUN,       -- Leg Sweep
        [853] = DR_CATEGORIES.STUN,          -- Hammer of Justice
        [408] = DR_CATEGORIES.STUN,          -- Kidney Shot
        [1833] = DR_CATEGORIES.STUN,         -- Cheap Shot
        [30283] = DR_CATEGORIES.STUN,        -- Shadowfury
        [132169] = DR_CATEGORIES.STUN,       -- Storm Bolt
        [179057] = DR_CATEGORIES.STUN,       -- Chaos Nova
        [117526] = DR_CATEGORIES.STUN,       -- Binding Shot
        
        [118] = DR_CATEGORIES.INCAPACITATE,  -- Polymorph
        [51514] = DR_CATEGORIES.INCAPACITATE, -- Hex
        [115078] = DR_CATEGORIES.INCAPACITATE, -- Paralysis
        [20066] = DR_CATEGORIES.INCAPACITATE, -- Repentance
        [9484] = DR_CATEGORIES.INCAPACITATE, -- Shackle Undead
        [6770] = DR_CATEGORIES.INCAPACITATE, -- Sap
        [3355] = DR_CATEGORIES.INCAPACITATE, -- Freezing Trap
        
        [15487] = DR_CATEGORIES.SILENCE,     -- Silence
        [2139] = DR_CATEGORIES.SILENCE,      -- Counterspell
        [1766] = DR_CATEGORIES.SILENCE,      -- Kick
        
        [339] = DR_CATEGORIES.ROOT,          -- Entangling Roots
        [122] = DR_CATEGORIES.ROOT,          -- Frost Nova
        [64695] = DR_CATEGORIES.ROOT,        -- Earthgrab
        
        [5782] = DR_CATEGORIES.DISORIENT,    -- Fear
        [605] = DR_CATEGORIES.DISORIENT,     -- Mind Control
        [8122] = DR_CATEGORIES.DISORIENT,    -- Psychic Scream
        [2094] = DR_CATEGORIES.DISORIENT     -- Blind
    }
end

-- Populate player-specific abilities based on class and spec
function PvPSystem:PopulatePlayerAbilities()
    -- Reset current abilities
    playerDefensiveCooldowns = {}
    playerOffensiveCooldowns = {}
    playerCCAbilities = {}
    
    -- Add class-specific abilities
    if currentClass == "WARRIOR" then
        -- Defensive cooldowns
        table.insert(playerDefensiveCooldowns, {id = 871, name = "Shield Wall"})
        table.insert(playerDefensiveCooldowns, {id = 12975, name = "Last Stand"})
        table.insert(playerDefensiveCooldowns, {id = 118038, name = "Die by the Sword"})
        
        -- Offensive cooldowns
        table.insert(playerOffensiveCooldowns, {id = 1719, name = "Recklessness"})
        table.insert(playerOffensiveCooldowns, {id = 107574, name = "Avatar"})
        
        -- CC abilities
        table.insert(playerCCAbilities, {id = 5246, name = "Intimidating Shout", category = DR_CATEGORIES.DISORIENT})
        table.insert(playerCCAbilities, {id = 132169, name = "Storm Bolt", category = DR_CATEGORIES.STUN})
        
    elseif currentClass == "PALADIN" then
        -- Defensive cooldowns
        table.insert(playerDefensiveCooldowns, {id = 642, name = "Divine Shield"})
        table.insert(playerDefensiveCooldowns, {id = 498, name = "Divine Protection"})
        
        -- Offensive cooldowns
        table.insert(playerOffensiveCooldowns, {id = 31884, name = "Avenging Wrath"})
        
        -- CC abilities
        table.insert(playerCCAbilities, {id = 853, name = "Hammer of Justice", category = DR_CATEGORIES.STUN})
        table.insert(playerCCAbilities, {id = 20066, name = "Repentance", category = DR_CATEGORIES.INCAPACITATE})
        
    elseif currentClass == "HUNTER" then
        -- Defensive cooldowns
        table.insert(playerDefensiveCooldowns, {id = 186265, name = "Aspect of the Turtle"})
        table.insert(playerDefensiveCooldowns, {id = 109304, name = "Exhilaration"})
        
        -- Offensive cooldowns
        table.insert(playerOffensiveCooldowns, {id = 193530, name = "Aspect of the Wild"})
        table.insert(playerOffensiveCooldowns, {id = 19574, name = "Bestial Wrath"})
        
        -- CC abilities
        table.insert(playerCCAbilities, {id = 187650, name = "Freezing Trap", category = DR_CATEGORIES.INCAPACITATE})
        table.insert(playerCCAbilities, {id = 117526, name = "Binding Shot", category = DR_CATEGORIES.ROOT})
        
    -- Add more classes as needed
    end
    
    -- Add spec-specific abilities based on currentSpec
    -- This would be expanded in a real implementation
end

-- Check if player is in PvP environment
function PvPSystem:CheckPvPStatus()
    -- Reset current status
    inPvP = false
    inArena = false
    inBattleground = false
    
    -- Check for arena
    local instanceType = select(2, IsInInstance())
    
    if instanceType == "arena" then
        inPvP = true
        inArena = true
        WR:Debug("PvPSystem: Entered Arena")
        self:PrepareArenaTracking()
    elseif instanceType == "pvp" then
        inPvP = true
        inBattleground = true
        WR:Debug("PvPSystem: Entered Battleground")
        self:PrepareBattlegroundTracking()
    elseif C_PvP and C_PvP.IsWarModeDesired and C_PvP.IsWarModeDesired() then
        inPvP = true
        WR:Debug("PvPSystem: War Mode active")
    end
    
    -- Update UI if status changed
    if settings.showPvPTeamDisplay then
        self:UpdatePvPUI()
    end
    
    -- Reset tracking data if we left PvP
    if not inPvP then
        enemyPlayers = {}
        friendlyPlayers = {}
        targetDR = {}
        enemyRoles = { healers = {}, damageDealers = {}, tanks = {} }
        enemyCooldowns = {}
        inBurstWindow = false
        defensiveNeedLevel = 0
        targetSwitchTarget = nil
        ccTarget = nil
        targetPriority = {}
    end
end

-- Prepare for arena match
function PvPSystem:PrepareArenaTracking()
    -- Clear existing data
    enemyPlayers = {}
    friendlyPlayers = {}
    
    -- Update group members
    self:UpdateGroupMembers()
    
    -- Get arena size
    local numOpponents = GetNumArenaOpponentSpecs()
    
    -- Pre-populate opponent slots
    for i = 1, numOpponents do
        local unit = "arena" .. i
        enemyPlayers[unit] = {
            unit = unit,
            guid = nil,
            name = nil,
            class = nil,
            spec = nil,
            role = nil,
            health = 1.0,
            auras = {},
            castingSpell = nil,
            isDead = false,
            drInfo = {},
            cooldowns = {},
            threatLevel = 0, -- 0-10 scale of how dangerous they are
            priority = 0     -- 0-10 scale of kill priority
        }
    end
end

-- Prepare for battleground
function PvPSystem:PrepareBattlegroundTracking()
    -- Clear existing data
    enemyPlayers = {}
    friendlyPlayers = {}
    
    -- Update group members
    self:UpdateGroupMembers()
    
    -- In battlegrounds, we'll populate enemies as we encounter them in combat
}

-- Process arena opponents when specs are available
function PvPSystem:ProcessArenaOpponents()
    local numOpponents = GetNumArenaOpponentSpecs()
    
    for i = 1, numOpponents do
        local unit = "arena" .. i
        local specID = GetArenaOpponentSpec(i)
        
        if specID and specID > 0 and enemyPlayers[unit] then
            local _, spec, _, _, role, class = GetSpecializationInfoByID(specID)
            
            -- Update enemy info
            enemyPlayers[unit].class = class
            enemyPlayers[unit].spec = spec
            enemyPlayers[unit].role = role
            enemyPlayers[unit].guid = UnitGUID(unit)
            enemyPlayers[unit].name = UnitName(unit)
            
            -- Categorize by role
            if role == "HEALER" then
                enemyRoles.healers[unit] = true
            elseif role == "DAMAGER" then
                enemyRoles.damageDealers[unit] = true
            elseif role == "TANK" then
                enemyRoles.tanks[unit] = true
            end
            
            -- Set initial threat and priority
            if role == "HEALER" then
                enemyPlayers[unit].threatLevel = 7
                enemyPlayers[unit].priority = 10
            elseif role == "DAMAGER" then
                enemyPlayers[unit].threatLevel = 9
                enemyPlayers[unit].priority = 8
            elseif role == "TANK" then
                enemyPlayers[unit].threatLevel = 4
                enemyPlayers[unit].priority = 5
            end
            
            -- Initialize cooldowns tracking for this class/spec
            self:InitializeEnemyCooldowns(unit, class, specID)
            
            WR:Debug("PvPSystem: Processed arena opponent " .. i .. ": " .. class .. " " .. (spec or "Unknown"))
        end
    end
    
    -- Update target priority list
    self:UpdateTargetPriority()
    
    -- Update UI
    if settings.showPvPTeamDisplay then
        self:UpdatePvPUI()
    end
end

-- Update arena opponent info when changed
function PvPSystem:UpdateArenaOpponent(unit, updateType)
    if not unit or not enemyPlayers[unit] then return end
    
    if updateType == "seen" then
        -- Update basic info
        enemyPlayers[unit].guid = UnitGUID(unit)
        enemyPlayers[unit].name = UnitName(unit)
        enemyPlayers[unit].isDead = UnitIsDead(unit)
        enemyPlayers[unit].health = UnitHealth(unit) / UnitHealthMax(unit)
        
        -- Scan for auras
        self:ScanUnitAuras(unit)
    elseif updateType == "destroyed" then
        enemyPlayers[unit].isDead = true
        enemyPlayers[unit].health = 0
    elseif updateType == "unseen" then
        -- Don't change too much, they might just be stealthed
    end
    
    -- Update target priority if needed
    self:UpdateTargetPriority()
    
    -- Update UI
    if settings.showPvPTeamDisplay then
        self:UpdatePvPUI()
    end
end

-- Process auras for tracking buffs/debuffs
function PvPSystem:ProcessAuras(unit)
    -- Check if this is a unit we're tracking
    if enemyPlayers[unit] then
        self:ScanUnitAuras(unit)
    elseif friendlyPlayers[unit] then
        self:ScanUnitAuras(unit)
    elseif unit == "player" then
        -- Check player defensives/vulnerabilities
        self:CheckPlayerStatus()
    end
end

-- Scan all auras on a unit
function PvPSystem:ScanUnitAuras(unit)
    if not UnitExists(unit) then return end
    
    local isEnemy = enemyPlayers[unit] ~= nil
    local unitTable = isEnemy and enemyPlayers[unit] or friendlyPlayers[unit]
    
    if not unitTable then return end
    
    -- Clear current auras
    unitTable.auras = {}
    
    -- Scan buffs
    local i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = UnitBuff(unit, i)
        
        if not name then break end
        
        -- Store aura info
        unitTable.auras[name] = {
            id = spellId,
            icon = icon,
            count = count,
            type = "BUFF",
            duration = duration,
            expirationTime = expirationTime,
            source = source
        }
        
        -- Track important buffs
        if isEnemy then
            self:TrackImportantBuff(unit, spellId, name, duration, expirationTime)
        end
        
        i = i + 1
    end
    
    -- Scan debuffs
    i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = UnitDebuff(unit, i)
        
        if not name then break end
        
        -- Store aura info
        unitTable.auras[name] = {
            id = spellId,
            icon = icon,
            count = count,
            type = "DEBUFF",
            debuffType = debuffType,
            duration = duration,
            expirationTime = expirationTime,
            source = source
        }
        
        -- Track CC debuffs for DR
        if isEnemy and ccAbilities[spellId] then
            self:TrackDiminishingReturn(unit, ccAbilities[spellId], duration, expirationTime)
        end
        
        i = i + 1
    end
    
    -- Update threat assessment if enemy
    if isEnemy then
        self:UpdateEnemyThreat(unit)
    end
    
    -- Update target priority if needed
    self:UpdateTargetPriority()
}

-- Track important buffs (defensive/offensive cooldowns)
function PvPSystem:TrackImportantBuff(unit, spellId, name, duration, expirationTime)
    -- Example cooldowns to track - this would be expanded in a real implementation
    local importantBuffs = {
        -- Defensive cooldowns
        [642] = {name = "Divine Shield", type = "defensive", duration = 8},
        [45438] = {name = "Ice Block", type = "defensive", duration = 10},
        [186265] = {name = "Aspect of the Turtle", type = "defensive", duration = 8},
        [33206] = {name = "Pain Suppression", type = "defensive", duration = 8},
        
        -- Offensive cooldowns
        [31884] = {name = "Avenging Wrath", type = "offensive", duration = 20},
        [1719] = {name = "Recklessness", type = "offensive", duration = 12},
        [12472] = {name = "Icy Veins", type = "offensive", duration = 20},
        [190319] = {name = "Combustion", type = "offensive", duration = 10}
    }
    
    local buffInfo = importantBuffs[spellId]
    if buffInfo then
        -- Store in enemy cooldowns
        if not enemyPlayers[unit].cooldowns then
            enemyPlayers[unit].cooldowns = {}
        end
        
        enemyPlayers[unit].cooldowns[spellId] = {
            id = spellId,
            name = buffInfo.name,
            type = buffInfo.type,
            expirationTime = expirationTime,
            active = true
        }
        
        -- If this is an offensive cooldown, increase threat level
        if buffInfo.type == "offensive" then
            enemyPlayers[unit].threatLevel = math.min(10, enemyPlayers[unit].threatLevel + 2)
            
            -- Check if we're the target and need defensives
            if UnitIsUnit(unit .. "target", "player") then
                defensiveNeedLevel = math.max(defensiveNeedLevel, 2)
            end
        end
        -- If defensive, decrease priority temporarily
        elseif buffInfo.type == "defensive" then
            enemyPlayers[unit].priority = math.max(1, enemyPlayers[unit].priority - 3)
        end
    end
}

-- Track diminishing returns for CC
function PvPSystem:TrackDiminishingReturn(unit, category, duration, expirationTime)
    if not category or not enemyPlayers[unit] then return end
    
    -- Make sure DR tracking exists
    if not enemyPlayers[unit].drInfo then
        enemyPlayers[unit].drInfo = {}
    end
    
    local now = GetTime()
    
    -- Get current DR level or initialize
    if not enemyPlayers[unit].drInfo[category] then
        enemyPlayers[unit].drInfo[category] = {
            level = 0,
            expirationTime = 0,
            resetTime = 0
        }
    end
    
    local drInfo = enemyPlayers[unit].drInfo[category]
    
    -- If DR has reset (18 seconds without that category of CC)
    if drInfo.resetTime < now then
        drInfo.level = 0
    end
    
    -- Record DR application
    drInfo.level = math.min(3, drInfo.level + 1) -- Increment DR level (cap at immune)
    drInfo.expirationTime = expirationTime
    drInfo.resetTime = expirationTime + 18 -- DR resets 18 seconds after previous CC ends
    
    -- Debug info
    WR:Debug("PvPSystem: Applied DR " .. category .. " to " .. unit .. " (Level: " .. drInfo.level .. ", Effect: " .. 
             DR_LEVELS[drInfo.level] * 100 .. "% duration)")
}

-- Check player's own status for defensive needs
function PvPSystem:CheckPlayerStatus()
    -- Reset defensive need level
    defensiveNeedLevel = 0
    
    -- Get player health percentage
    local healthPct = UnitHealth("player") / UnitHealthMax("player")
    
    -- Adjust defensive need based on health
    if healthPct < 0.3 then
        defensiveNeedLevel = 3 -- Critical need
    elseif healthPct < 0.5 then
        defensiveNeedLevel = 2 -- High need
    elseif healthPct < 0.7 then
        defensiveNeedLevel = 1 -- Moderate need
    end
    
    -- Check for burst damage taken (would track damage spikes in real implementation)
    
    -- Check how many enemies are targeting us
    local targetsOnUs = 0
    for unit, info in pairs(enemyPlayers) do
        if UnitExists(unit) and UnitIsUnit(unit .. "target", "player") then
            targetsOnUs = targetsOnUs + 1
            
            -- If a high threat enemy is targeting us, increase defensive need
            if info.threatLevel >= 8 then
                defensiveNeedLevel = math.max(defensiveNeedLevel, 2)
            end
        end
    end
    
    -- Multiple enemies focusing us is dangerous
    if targetsOnUs >= 2 then
        defensiveNeedLevel = math.max(defensiveNeedLevel, 2)
    end
    
    -- Check for enemy offensive cooldowns active
    for unit, info in pairs(enemyPlayers) do
        if info.cooldowns then
            for id, cooldown in pairs(info.cooldowns) do
                if cooldown.type == "offensive" and cooldown.active and 
                   UnitIsUnit(unit .. "target", "player") then
                    defensiveNeedLevel = math.max(defensiveNeedLevel, 2)
                end
            end
        end
    end
}

-- Process combat log events for tracking
function PvPSystem:ProcessCombatLog(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                   destGUID, destName, destFlags, destRaidFlags, spellID, spellName, ...)
    -- Track based on event type
    if event == "SPELL_CAST_SUCCESS" then
        self:TrackSpellCastSuccess(sourceGUID, sourceName, spellID, spellName)
    elseif event == "SPELL_AURA_APPLIED" then
        self:TrackAuraApplied(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    elseif event == "SPELL_AURA_REMOVED" then
        self:TrackAuraRemoved(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    elseif event == "UNIT_DIED" then
        self:TrackUnitDied(destGUID, destName)
    end
end

-- Track successful spell casts (especially cooldowns)
function PvPSystem:TrackSpellCastSuccess(sourceGUID, sourceName, spellID, spellName)
    -- Find the unit that cast this
    local sourceUnit = self:GetUnitFromGUID(sourceGUID)
    if not sourceUnit then return end
    
    -- Track enemy cooldown usage
    if enemyPlayers[sourceUnit] then
        -- Check if this is a tracked cooldown
        local cooldownInfo = self:GetCooldownInfo(spellID, enemyPlayers[sourceUnit].class)
        if cooldownInfo then
            -- Start cooldown tracking
            if not enemyPlayers[sourceUnit].cooldowns then
                enemyPlayers[sourceUnit].cooldowns = {}
            end
            
            -- Record activation
            local now = GetTime()
            enemyPlayers[sourceUnit].cooldowns[spellID] = {
                id = spellID,
                name = spellName,
                type = cooldownInfo.type,
                startTime = now,
                duration = cooldownInfo.duration,
                expirationTime = now + cooldownInfo.duration,
                active = cooldownInfo.type == "offensive" or cooldownInfo.type == "defensive",
                onCooldown = true
            }
            
            -- Update threats and priorities
            if cooldownInfo.type == "offensive" then
                enemyPlayers[sourceUnit].threatLevel = math.min(10, enemyPlayers[sourceUnit].threatLevel + 2)
                
                -- Check if we need defensives
                if UnitIsUnit(sourceUnit .. "target", "player") then
                    defensiveNeedLevel = math.max(defensiveNeedLevel, 2)
                end
            elseif cooldownInfo.type == "defensive" then
                enemyPlayers[sourceUnit].priority = math.max(1, enemyPlayers[sourceUnit].priority - 3)
            end
            
            WR:Debug("PvPSystem: Tracked " .. sourceName .. " cooldown: " .. spellName)
        end
    end
}

-- Track aura applications
function PvPSystem:TrackAuraApplied(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Check for important debuffs (CC) applied to friends
    if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
        -- Check if this is a CC
        local ccCategory = ccAbilities[spellID]
        if ccCategory then
            -- Find the friendly unit
            local friendUnit = self:GetUnitFromGUID(destGUID)
            if friendUnit then
                -- Record CC application
                -- In a real implementation, this would manage break priorities
                WR:Debug("PvPSystem: CC " .. spellName .. " applied to friendly " .. destName)
            end
        end
    end
}

-- Track aura removals
function PvPSystem:TrackAuraRemoved(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Find the unit this was removed from
    local destUnit = self:GetUnitFromGUID(destGUID)
    if not destUnit then return end
    
    -- Check if this was an important cooldown
    if enemyPlayers[destUnit] and enemyPlayers[destUnit].cooldowns and 
       enemyPlayers[destUnit].cooldowns[spellID] then
        
        -- Mark as inactive but still on cooldown
        enemyPlayers[destUnit].cooldowns[spellID].active = false
        
        -- Update threat if needed
        if enemyPlayers[destUnit].cooldowns[spellID].type == "offensive" then
            enemyPlayers[destUnit].threatLevel = math.max(0, enemyPlayers[destUnit].threatLevel - 2)
        elseif enemyPlayers[destUnit].cooldowns[spellID].type == "defensive" then
            -- Restore target priority as defensive faded
            self:UpdateTargetPriority()
        end
    end
}

-- Track unit deaths
function PvPSystem:TrackUnitDied(unitGUID, unitName)
    -- Find the unit
    local unit = self:GetUnitFromGUID(unitGUID)
    if not unit then return end
    
    -- Update enemy tracking if applicable
    if enemyPlayers[unit] then
        enemyPlayers[unit].isDead = true
        enemyPlayers[unit].health = 0
        enemyPlayers[unit].priority = 0
        enemyPlayers[unit].threatLevel = 0
        
        -- Update target priorities
        self:UpdateTargetPriority()
    end
}

-- Process spell cast starts for interrupt detection
function PvPSystem:ProcessSpellCastStart(unit, spellID)
    -- Check if this is an enemy
    if not enemyPlayers[unit] then return end
    
    -- Store casting info
    enemyPlayers[unit].castingSpell = {
        id = spellID,
        name = GetSpellInfo(spellID) or "Unknown",
        startTime = GetTime(),
        endTime = GetTime() + (select(4, UnitCastingInfo(unit)) or 1000) / 1000,
        interruptible = not (select(8, UnitCastingInfo(unit))),
        importance = self:GetSpellImportance(spellID)
    }
    
    -- Adjust interrupt priority based on spell importance
    if settings.autoInterrupt and enemyPlayers[unit].castingSpell.interruptible then
        -- If this is a high-importance spell, flag for interruption
        if enemyPlayers[unit].castingSpell.importance >= 8 then
            -- In a real implementation, this would trigger interrupt logic
            WR:Debug("PvPSystem: High-priority interrupt needed for " .. unit)
        end
    end
}

-- Process successful spell casts
function PvPSystem:ProcessSpellCastSuccess(unit, spellID)
    -- Clear casting info
    if enemyPlayers[unit] then
        enemyPlayers[unit].castingSpell = nil
    end
}

-- Process health updates
function PvPSystem:ProcessHealthUpdate(unit)
    if not UnitExists(unit) then return end
    
    -- Update enemy health
    if enemyPlayers[unit] then
        local old = enemyPlayers[unit].health or 1
        enemyPlayers[unit].health = UnitHealth(unit) / UnitHealthMax(unit)
        
        -- Check for burst opportunity (big health drop)
        if old - enemyPlayers[unit].health > 0.2 and enemyPlayers[unit].health < 0.5 then
            -- Flag as potential burst target
            targetSwitchTarget = unit
            inBurstWindow = true
            
            WR:Debug("PvPSystem: Burst opportunity on " .. UnitName(unit))
        end
    end
    
    -- Check player health for defensive needs
    if unit == "player" then
        self:CheckPlayerStatus()
    end
}

-- Update group members for tracking
function PvPSystem:UpdateGroupMembers()
    -- Clear current list
    friendlyPlayers = {}
    
    -- Add player
    friendlyPlayers["player"] = {
        unit = "player",
        guid = UnitGUID("player"),
        name = UnitName("player"),
        class = select(2, UnitClass("player")),
        spec = GetSpecialization(),
        role = GetSpecializationRole(GetSpecialization()),
        health = UnitHealth("player") / UnitHealthMax("player"),
        auras = {},
        isDead = UnitIsDead("player")
    }
    
    -- Process group members
    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()
    local unitPrefix = IsInRaid() and "raid" or "party"
    
    for i = 1, numMembers do
        local unit = unitPrefix .. i
        if unit ~= "party0" and UnitExists(unit) then
            friendlyPlayers[unit] = {
                unit = unit,
                guid = UnitGUID(unit),
                name = UnitName(unit),
                class = select(2, UnitClass(unit)),
                role = UnitGroupRolesAssigned(unit),
                health = UnitHealth(unit) / UnitHealthMax(unit),
                auras = {},
                isDead = UnitIsDead(unit)
            }
        end
    end
}

-- Update enemy threat assessment
function PvPSystem:UpdateEnemyThreat(unit)
    if not enemyPlayers[unit] then return end
    
    -- Start with base threat by role
    local threatLevel = 0
    if enemyPlayers[unit].role == "HEALER" then
        threatLevel = 7
    elseif enemyPlayers[unit].role == "DAMAGER" then
        threatLevel = 8
    elseif enemyPlayers[unit].role == "TANK" then
        threatLevel = 4
    end
    
    -- Adjust based on offensive cooldowns
    if enemyPlayers[unit].cooldowns then
        for _, cooldown in pairs(enemyPlayers[unit].cooldowns) do
            if cooldown.type == "offensive" and cooldown.active then
                threatLevel = threatLevel + 2
            end
        end
    end
    
    -- Adjust based on health (lower health = less threat)
    if enemyPlayers[unit].health < 0.3 then
        threatLevel = threatLevel - 3
    elseif enemyPlayers[unit].health < 0.5 then
        threatLevel = threatLevel - 1
    end
    
    -- Adjust based on CC status
    for category, drInfo in pairs(enemyPlayers[unit].drInfo or {}) do
        if drInfo.expirationTime > GetTime() then
            -- Currently under CC, less of a threat
            threatLevel = threatLevel - 2
        end
    end
    
    -- Clamp to valid range
    threatLevel = math.max(0, math.min(10, threatLevel))
    
    -- Update threat level
    enemyPlayers[unit].threatLevel = threatLevel
}

-- Update target priority list
function PvPSystem:UpdateTargetPriority()
    -- Reset target priorities
    targetPriority = {}
    
    -- Build sorted list of targets
    for unit, info in pairs(enemyPlayers) do
        if UnitExists(unit) and not info.isDead then
            -- Start with base priority by role
            local priority = 0
            if info.role == "HEALER" then
                priority = settings.prioritizeHealers and 10 or 8
            elseif info.role == "DAMAGER" then
                priority = 7
            elseif info.role == "TANK" then
                priority = 4
            end
            
            -- Lower priority if they have strong defensives up
            if info.cooldowns then
                for _, cooldown in pairs(info.cooldowns) do
                    if cooldown.type == "defensive" and cooldown.active then
                        priority = priority - 3
                    end
                end
            end
            
            -- Increase priority for low health targets
            if info.health < 0.3 then
                priority = priority + 3
            elseif info.health < 0.5 then
                priority = priority + 1
            end
            
            -- Increase priority for current target (momentum)
            if UnitIsUnit("target", unit) then
                priority = priority + 1
            end
            
            -- Increase priority for crowd controlled targets (easier kills)
            for category, drInfo in pairs(info.drInfo or {}) do
                if drInfo.expirationTime > GetTime() then
                    priority = priority + 1
                end
            end
            
            -- Store updated priority
            info.priority = math.max(0, math.min(10, priority))
            
            -- Add to priority list
            table.insert(targetPriority, {
                unit = unit,
                name = info.name,
                priority = info.priority,
                health = info.health,
                class = info.class,
                role = info.role
            })
        end
    end
    
    -- Sort by priority (highest first)
    table.sort(targetPriority, function(a, b)
        if a.priority == b.priority then
            return a.health < b.health  -- If same priority, target lowest health
        else
            return a.priority > b.priority
        end
    end)
    
    -- Update target switch recommendation
    if #targetPriority > 0 then
        -- Recommend switching if current target isn't top priority and the difference is significant
        local currentTargetPriority = 0
        for _, target in ipairs(targetPriority) do
            if UnitIsUnit("target", target.unit) then
                currentTargetPriority = target.priority
                break
            end
        end
        
        if targetPriority[1].priority > currentTargetPriority + 2 then
            targetSwitchTarget = targetPriority[1].unit
        end
    end
}

-- Initialize enemy cooldown tracking based on class/spec
function PvPSystem:InitializeEnemyCooldowns(unit, class, specID)
    if not enemyPlayers[unit] then return end
    
    -- Initialize cooldowns table
    enemyPlayers[unit].cooldowns = {}
    
    -- Add class-specific cooldowns to track
    -- This would be expanded in a real implementation with a comprehensive database
    -- of important cooldowns for each class and spec
    local cooldowns = self:GetClassCooldowns(class, specID)
    
    for _, cooldown in ipairs(cooldowns) do
        enemyPlayers[unit].cooldowns[cooldown.id] = {
            id = cooldown.id,
            name = cooldown.name,
            type = cooldown.type,
            duration = cooldown.duration,
            active = false,
            onCooldown = false,
            startTime = 0,
            expirationTime = 0
        }
    end
}

-- Get class-specific cooldowns to track
function PvPSystem:GetClassCooldowns(class, specID)
    -- This would be a comprehensive database in a real implementation
    -- For demonstration, we'll use a simplified version
    
    local cooldowns = {}
    
    if class == "WARRIOR" then
        table.insert(cooldowns, {id = 1719, name = "Recklessness", type = "offensive", duration = 12})
        table.insert(cooldowns, {id = 107574, name = "Avatar", type = "offensive", duration = 20})
        table.insert(cooldowns, {id = 871, name = "Shield Wall", type = "defensive", duration = 8})
        table.insert(cooldowns, {id = 12975, name = "Last Stand", type = "defensive", duration = 8})
        table.insert(cooldowns, {id = 118038, name = "Die by the Sword", type = "defensive", duration = 8})
    elseif class == "PALADIN" then
        table.insert(cooldowns, {id = 31884, name = "Avenging Wrath", type = "offensive", duration = 20})
        table.insert(cooldowns, {id = 642, name = "Divine Shield", type = "defensive", duration = 8})
        table.insert(cooldowns, {id = 498, name = "Divine Protection", type = "defensive", duration = 8})
        table.insert(cooldowns, {id = 6940, name = "Blessing of Sacrifice", type = "defensive", duration = 12})
    elseif class == "HUNTER" then
        table.insert(cooldowns, {id = 193530, name = "Aspect of the Wild", type = "offensive", duration = 20})
        table.insert(cooldowns, {id = 19574, name = "Bestial Wrath", type = "offensive", duration = 15})
        table.insert(cooldowns, {id = 186265, name = "Aspect of the Turtle", type = "defensive", duration = 8})
        table.insert(cooldowns, {id = 109304, name = "Exhilaration", type = "defensive", duration = 30})
    -- Add more classes as needed
    end
    
    return cooldowns
}

-- Get info about a specific cooldown
function PvPSystem:GetCooldownInfo(spellID, class)
    -- This would be expanded in a real implementation
    local cooldownDB = {
        -- Warrior
        [1719] = {type = "offensive", duration = 90}, -- Recklessness
        [107574] = {type = "offensive", duration = 90}, -- Avatar
        [871] = {type = "defensive", duration = 240}, -- Shield Wall
        [12975] = {type = "defensive", duration = 180}, -- Last Stand
        [118038] = {type = "defensive", duration = 120}, -- Die by the Sword
        
        -- Paladin
        [31884] = {type = "offensive", duration = 120}, -- Avenging Wrath
        [642] = {type = "defensive", duration = 300}, -- Divine Shield
        [498] = {type = "defensive", duration = 60}, -- Divine Protection
        [6940] = {type = "defensive", duration = 120}, -- Blessing of Sacrifice
        
        -- Hunter
        [193530] = {type = "offensive", duration = 120}, -- Aspect of the Wild
        [19574] = {type = "offensive", duration = 90}, -- Bestial Wrath
        [186265] = {type = "defensive", duration = 180}, -- Aspect of the Turtle
        [109304] = {type = "defensive", duration = 120} -- Exhilaration
    }
    
    return cooldownDB[spellID]
end

-- Get rating of how important it is to interrupt a spell (0-10)
function PvPSystem:GetSpellImportance(spellID)
    -- This would be a comprehensive database in a real implementation
    -- For demonstration, we'll use a simplified version
    
    local importantSpells = {
        -- Healing spells
        [2060] = 9,  -- Heal
        [2061] = 8,  -- Flash Heal
        [8936] = 9,  -- Regrowth
        [77472] = 10, -- Healing Wave
        [19750] = 8,  -- Flash of Light
        
        -- CC spells
        [118] = 7,    -- Polymorph
        [51514] = 7,  -- Hex
        [605] = 10,   -- Mind Control
        
        -- Major damage spells
        [203286] = 8, -- Greater Pyroblast
        
        -- Default importance for unknown spells
        ["default"] = 5
    }
    
    return importantSpells[spellID] or importantSpells["default"]
end

-- Get current PvP status
function PvPSystem:GetPvPStatus()
    return {
        inPvP = inPvP,
        inArena = inArena,
        inBattleground = inBattleground,
        defensiveNeedLevel = defensiveNeedLevel,
        inBurstWindow = inBurstWindow,
        targetSwitchTarget = targetSwitchTarget,
        ccTarget = ccTarget,
        enemyCount = self:TableSize(enemyPlayers),
        healerCount = self:TableSize(enemyRoles.healers),
        settings = settings
    }
end

-- Get target priority list
function PvPSystem:GetTargetPriority()
    return targetPriority
end

-- Get enemy data
function PvPSystem:GetEnemyData(unit)
    return enemyPlayers[unit]
end

-- Get all enemy data
function PvPSystem:GetAllEnemies()
    return enemyPlayers
end

-- Get enemy by GUID
function PvPSystem:GetEnemyByGUID(guid)
    for unit, info in pairs(enemyPlayers) do
        if info.guid == guid then
            return unit, info
        end
    end
    return nil
end

-- Get unit from GUID
function PvPSystem:GetUnitFromGUID(guid)
    -- Check enemies
    for unit, info in pairs(enemyPlayers) do
        if info.guid == guid then
            return unit
        end
    end
    
    -- Check friendlies
    for unit, info in pairs(friendlyPlayers) do
        if info.guid == guid then
            return unit
        end
    end
    
    return nil
end

-- Check if a unit has a specific DR category currently applied
function PvPSystem:HasActiveDR(unit, category)
    if not enemyPlayers[unit] or not enemyPlayers[unit].drInfo or
       not enemyPlayers[unit].drInfo[category] then
        return false
    end
    
    return enemyPlayers[unit].drInfo[category].expirationTime > GetTime()
end

-- Get current DR level for a category on a unit (0=none, 1=50%, 2=75%, 3=immune)
function PvPSystem:GetDRLevel(unit, category)
    if not enemyPlayers[unit] or not enemyPlayers[unit].drInfo or
       not enemyPlayers[unit].drInfo[category] then
        return 0
    end
    
    if enemyPlayers[unit].drInfo[category].resetTime < GetTime() then
        return 0 -- DR has reset
    end
    
    return enemyPlayers[unit].drInfo[category].level
end

-- Get effective CC duration after DR
function PvPSystem:GetEffectiveDebuffDuration(unit, category, baseDuration)
    local drLevel = self:GetDRLevel(unit, category)
    return baseDuration * DR_LEVELS[drLevel]
end

-- Check if a unit is in CC
function PvPSystem:IsInCC(unit)
    if not enemyPlayers[unit] or not enemyPlayers[unit].drInfo then
        return false
    end
    
    for category, drInfo in pairs(enemyPlayers[unit].drInfo) do
        if drInfo.expirationTime > GetTime() then
            return true
        end
    end
    
    return false
end

-- Get abilities adjusted for PvP situations
function PvPSystem:GetPvPRotationAdjustments()
    if not inPvP then
        return nil
    end
    
    local adjustments = {
        prioritizeDefensives = (defensiveNeedLevel > 1),
        prioritizeOffensives = inBurstWindow,
        prioritizeCC = false,
        targetSwitchRecommended = targetSwitchTarget ~= nil,
        recommendedTarget = targetSwitchTarget,
        interruptTarget = nil,
        interruptPriority = 0,
        abilityModifiers = {}
    }
    
    -- Check for enemy healer that needs interrupting
    for unit, info in pairs(enemyPlayers) do
        if info.role == "HEALER" and info.castingSpell and info.castingSpell.interruptible then
            -- Healers casting interruptible spells get high interrupt priority
            if info.castingSpell.importance >= 8 or 
               (info.castingSpell.name:lower():find("heal") or 
                info.castingSpell.name:lower():find("rejuv") or
                info.castingSpell.name:lower():find("renew")) then
                
                adjustments.interruptTarget = unit
                adjustments.interruptPriority = 9
                
                -- Prioritize interrupt abilities
                for _, abilityID in ipairs(interruptAbilities[currentClass] or {}) do
                    adjustments.abilityModifiers[abilityID] = 10.0 -- Very high priority
                end
                
                break
            end
        end
    end
    
    -- If we need to use defensives
    if defensiveNeedLevel >= 2 then
        for _, ability in ipairs(playerDefensiveCooldowns) do
            -- Increase priority based on need level
            adjustments.abilityModifiers[ability.id] = 1.0 + (defensiveNeedLevel * 0.5)
        end
    end
    
    -- If we're in a burst window
    if inBurstWindow then
        for _, ability in ipairs(playerOffensiveCooldowns) do
            adjustments.abilityModifiers[ability.id] = 2.0 -- High priority for offensive cooldowns
        end
    end
    
    -- CC priority adjustments - find best CC target
    ccTarget = nil
    for unit, info in pairs(enemyPlayers) do
        if not self:IsInCC(unit) and 
           ((info.castingSpell and info.castingSpell.importance >= 8) or info.role == "HEALER") then
            
            -- Find a CC that won't be affected by DR
            for _, ability in ipairs(playerCCAbilities) do
                if self:GetDRLevel(unit, ability.category) < 3 then -- Not immune
                    ccTarget = unit
                    adjustments.abilityModifiers[ability.id] = 1.5 -- Boost CC priority
                    break
                end
            end
            
            if ccTarget then break end
        end
    end
    
    return adjustments
end

-- Initialize the PvP UI
function PvPSystem:InitializeUI()
    -- This would create the UI elements for displaying enemy and friendly unit frames
    -- Simplified for demonstration
    -- A real implementation would create unit frames, DR trackers, etc.
    
    WR:Debug("PvPSystem: Initialized UI")
end

-- Update the PvP UI with current data
function PvPSystem:UpdatePvPUI()
    -- This would update the UI elements with current data
    -- Simplified for demonstration
    
    if not inPvP then
        -- Hide PvP UI when not in PvP
        return
    end
}

-- Load PvP-specific profiles
function PvPSystem:LoadPvPProfiles()
    -- This would load PvP-specific action profiles
    -- Simplified for demonstration
    
    WR:Debug("PvPSystem: Loaded PvP profiles")
}

-- Register with the RotationEnhancer
function PvPSystem:RegisterWithRotationEnhancer()
    if WR.RotationEnhancer then
        WR.RotationEnhancer:RegisterPvPHandler(function(abilities)
            -- Only modify if in PvP
            if not inPvP then
                return abilities
            end
            
            -- Get PvP adjustments
            local pvpAdjustments = self:GetPvPRotationAdjustments()
            if not pvpAdjustments then
                return abilities
            end
            
            -- Apply adjustments to abilities
            for i, ability in ipairs(abilities) do
                -- Apply general category adjustments
                if pvpAdjustments.prioritizeDefensives and self:IsDefensiveAbility(ability.id) then
                    ability.score = ability.score * 2.0
                    ability.pvpAdjusted = true
                end
                
                if pvpAdjustments.prioritizeOffensives and self:IsOffensiveAbility(ability.id) then
                    ability.score = ability.score * 1.8
                    ability.pvpAdjusted = true
                end
                
                if pvpAdjustments.prioritizeCC and self:IsCCAbility(ability.id) then
                    ability.score = ability.score * 1.5
                    ability.pvpAdjusted = true
                end
                
                -- Apply specific ability adjustments
                local specificMod = pvpAdjustments.abilityModifiers[ability.id]
                if specificMod then
                    ability.score = ability.score * specificMod
                    ability.pvpAdjusted = true
                end
            end
            
            return abilities
        end)
    end
}

-- Helper function to check if an ability is defensive
function PvPSystem:IsDefensiveAbility(spellID)
    for _, ability in ipairs(playerDefensiveCooldowns) do
        if ability.id == spellID then
            return true
        end
    end
    return false
end

-- Helper function to check if an ability is offensive
function PvPSystem:IsOffensiveAbility(spellID)
    for _, ability in ipairs(playerOffensiveCooldowns) do
        if ability.id == spellID then
            return true
        end
    end
    return false
end

-- Helper function to check if an ability is CC
function PvPSystem:IsCCAbility(spellID)
    for _, ability in ipairs(playerCCAbilities) do
        if ability.id == spellID then
            return true
        end
    end
    return ccAbilities[spellID] ~= nil
end

-- Helper to get table size
function PvPSystem:TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Get settings
function PvPSystem:GetSettings()
    return settings
end

-- Update settings
function PvPSystem:UpdateSettings(newSettings)
    if not newSettings then return end
    
    for k, v in pairs(newSettings) do
        if settings[k] ~= nil then
            settings[k] = v
        end
    end
    
    self:SaveData()
}

-- Handle command line
function PvPSystem:HandleCommand(cmd)
    if not cmd or cmd == "" then
        -- Show status
        self:ShowStatus()
        return
    end
    
    local command, param = cmd:match("^(%S+)%s*(.*)$")
    command = command:lower()
    
    if command == "enable" then
        settings.enablePvPOptimization = true
        self:SaveData()
        WR:Print("PvP optimization enabled")
    elseif command == "disable" then
        settings.enablePvPOptimization = false
        self:SaveData()
        WR:Print("PvP optimization disabled")
    elseif command == "status" then
        self:ShowStatus()
    elseif command == "settings" then
        if param == "" then
            self:ShowSettings()
        else
            local setting, value = param:match("(%S+)%s+(.+)")
            if setting and value and settings[setting] ~= nil then
                -- Convert value based on setting type
                if type(settings[setting]) == "boolean" then
                    value = value:lower()
                    settings[setting] = (value == "true" or value == "yes" or value == "1" or value == "on")
                else
                    settings[setting] = value
                end
                
                self:SaveData()
                WR:Print("Updated setting: " .. setting .. " = " .. tostring(settings[setting]))
            else
                WR:Print("Unknown setting: " .. (setting or ""))
            end
        end
    elseif command == "enemies" then
        self:ShowEnemies()
    elseif command == "friends" then
        self:ShowFriends()
    elseif command == "target" then
        self:ShowTargetInfo()
    else
        WR:Print("Unknown PvP command: " .. command)
        WR:Print("Available commands: enable, disable, status, settings, enemies, friends, target")
    end
end

-- Show current status
function PvPSystem:ShowStatus()
    WR:Print("PvP System Status:")
    WR:Print("Optimization: " .. (settings.enablePvPOptimization and "Enabled" or "Disabled"))
    WR:Print("In PvP: " .. (inPvP and "Yes" or "No"))
    
    if inPvP then
        WR:Print("Arena: " .. (inArena and "Yes" or "No"))
        WR:Print("Battleground: " .. (inBattleground and "Yes" or "No"))
        WR:Print("Defensive Need: " .. defensiveNeedLevel .. "/3")
        WR:Print("Burst Window: " .. (inBurstWindow and "Yes" or "No"))
        WR:Print("Enemies Tracked: " .. self:TableSize(enemyPlayers))
        WR:Print("Enemy Healers: " .. self:TableSize(enemyRoles.healers))
    end
}

-- Show current settings
function PvPSystem:ShowSettings()
    WR:Print("PvP System Settings:")
    
    for k, v in pairs(settings) do
        WR:Print("  " .. k .. ": " .. tostring(v))
    end
    
    WR:Print("Use '/wr pvp settings <name> <value>' to change")
}

-- Show enemy info
function PvPSystem:ShowEnemies()
    if not inPvP or self:TableSize(enemyPlayers) == 0 then
        WR:Print("No enemies currently tracked")
        return
    end
    
    WR:Print("Tracked Enemies:")
    for unit, info in pairs(enemyPlayers) do
        if UnitExists(unit) then
            WR:Print(string.format("%s: %s %s (%s) - Health: %.0f%%, Threat: %d, Priority: %d",
                unit, info.name, info.class, info.role or "Unknown",
                info.health * 100, info.threatLevel, info.priority))
        end
    end
}

-- Show friendly info
function PvPSystem:ShowFriends()
    if not inPvP or self:TableSize(friendlyPlayers) == 0 then
        WR:Print("No friends currently tracked")
        return
    end
    
    WR:Print("Tracked Friends:")
    for unit, info in pairs(friendlyPlayers) do
        if UnitExists(unit) then
            WR:Print(string.format("%s: %s (%s) - Health: %.0f%%",
                unit, info.name, info.role or "Unknown", info.health * 100))
        end
    end
}

-- Show target info
function PvPSystem:ShowTargetInfo()
    if not UnitExists("target") then
        WR:Print("No target selected")
        return
    end
    
    local targetUnit = "target"
    local targetGUID = UnitGUID("target")
    
    -- Find arena unit if possible
    for unit, info in pairs(enemyPlayers) do
        if info.guid == targetGUID then
            targetUnit = unit
            break
        end
    end
    
    if not enemyPlayers[targetUnit] then
        WR:Print("Target is not a tracked enemy")
        return
    end
    
    local info = enemyPlayers[targetUnit]
    
    WR:Print("Target: " .. info.name .. " (" .. info.class .. " " .. (info.spec or "Unknown") .. ")")
    WR:Print("Role: " .. (info.role or "Unknown"))
    WR:Print("Health: " .. math.floor(info.health * 100) .. "%")
    WR:Print("Threat Level: " .. info.threatLevel .. "/10")
    WR:Print("Priority: " .. info.priority .. "/10")
    
    -- Show active auras
    local auraCount = 0
    for name, aura in pairs(info.auras or {}) do
        auraCount = auraCount + 1
        if auraCount <= 5 then  -- Limit to first 5 auras to avoid spam
            local remaining = aura.expirationTime and math.max(0, aura.expirationTime - GetTime()) or 0
            WR:Print("Aura: " .. name .. (remaining > 0 and " (" .. math.floor(remaining) .. "s)" or ""))
        end
    end
    
    if auraCount > 5 then
        WR:Print("... and " .. (auraCount - 5) .. " more auras")
    end
    
    -- Show DR info
    local drCount = 0
    for category, drInfo in pairs(info.drInfo or {}) do
        drCount = drCount + 1
        local drLevel = self:GetDRLevel(targetUnit, category)
        local drEffect = DR_LEVELS[drLevel] * 100
        WR:Print("DR - " .. category .. ": " .. drEffect .. "% effectiveness")
    end
}

-- Initialize the module
PvPSystem:Initialize()

return PvPSystem