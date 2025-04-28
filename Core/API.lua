------------------------------------------
-- WindrunnerRotations - API
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local API = {}
WR.API = API

-- Local variables
local addonVersion = "1.0.0"
local buildNumber = 10010
local eventFrame = nil
local eventHandlers = {}
local throttledFunctions = {}
local cooldownCache = {}
local unitCache = {}
local spellCache = {}
local cacheTimeout = 1.0 -- Cache timeout in seconds
local debugMode = false
local printPrefix = "|cFF00FF00WindrunnerRotations|r: "
local unitIterators = {}
local globalCooldown = 0
local lastGCDUpdate = 0
local gcdSpellID = 61304
local playerGUID = nil
local playerClass, playerClassName = nil, nil
local playerLevel = 0
local playerSpecID = 0
local playerSpecName = ""
local playerRole = ""
local playerFaction = ""
local playerRace = ""
local playerRaceName = ""
local playerCovenantID = 0
local playerItems = {}
local itemSlotNames = {
    [1] = "HeadSlot",
    [2] = "NeckSlot",
    [3] = "ShoulderSlot",
    [4] = "BackSlot",
    [5] = "ChestSlot",
    [6] = "WristSlot",
    [7] = "HandsSlot",
    [8] = "WaistSlot",
    [9] = "LegsSlot",
    [10] = "FeetSlot",
    [11] = "Finger0Slot",
    [12] = "Finger1Slot",
    [13] = "Trinket0Slot",
    [14] = "Trinket1Slot",
    [15] = "MainHandSlot",
    [16] = "SecondaryHandSlot"
}
local spellKnown = {}
local spellKnownRefreshTime = 0
local SPELL_KNOWN_REFRESH_INTERVAL = 10 -- Refresh spell known cache every 10 seconds
local tinkrLoaded = false
local tinkrAPI = nil
local loadErrors = {}

-- Spell Schools
local SCHOOL_NONE = 0x00
local SCHOOL_PHYSICAL = 0x01
local SCHOOL_HOLY = 0x02
local SCHOOL_FIRE = 0x04
local SCHOOL_NATURE = 0x08
local SCHOOL_FROST = 0x10
local SCHOOL_SHADOW = 0x20
local SCHOOL_ARCANE = 0x40

-- Initialize API
function API.Initialize()
    -- Create event frame
    API.CreateEventFrame()
    
    -- Initialize unit iterators
    API.InitializeUnitIterators()
    
    -- Get player info
    API.UpdatePlayerInfo()
    
    -- Register events
    API.RegisterInitialEvents()
    
    -- Initialize Tinkr API if available
    API.InitializeTinkrAPI()
    
    -- Initialize defensive tracking
    API.InitializeDefensiveTracking()
    
    -- Register common encounter data
    API.RegisterCommonEncounters()
    
    API.PrintDebug("API initialized")
    return true
end

-- Create event frame
function API.CreateEventFrame()
    eventFrame = CreateFrame("Frame", "WindrunnerRotationsEventFrame")
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        API.ProcessEvent(event, ...)
    end)
end

-- Initialize unit iterators
function API.InitializeUnitIterators()
    -- Party iterator
    unitIterators.party = function()
        local index = 0
        local size = GetNumGroupMembers()
        
        return function()
            index = index + 1
            if index == 1 then
                return "player"
            elseif index <= size then
                return "party" .. (index - 1)
            end
            return nil
        end
    end
    
    -- Raid iterator
    unitIterators.raid = function()
        local index = 0
        local size = GetNumGroupMembers()
        
        return function()
            index = index + 1
            if index <= size then
                if IsInRaid() then
                    return "raid" .. index
                elseif index == 1 then
                    return "player"
                else
                    return "party" .. (index - 1)
                end
            end
            return nil
        end
    end
    
    -- Enemies iterator
    unitIterators.enemies = function(unit, distance)
        local index = 0
        local units = API.GetEnemiesInRange(unit, distance)
        
        return function()
            index = index + 1
            if index <= #units then
                return units[index]
            end
            return nil
        end
    end
    
    -- Arena enemies iterator
    unitIterators.arena = function()
        local index = 0
        
        return function()
            index = index + 1
            if index <= 5 then
                local unit = "arena" .. index
                if UnitExists(unit) then
                    return unit
                end
            end
            return nil
        end
    end
end

-- Update player info
function API.UpdatePlayerInfo()
    -- Get player GUID
    playerGUID = UnitGUID("player")
    
    -- Get player class
    playerClassName, playerClass = UnitClass("player")
    
    -- Get player level
    playerLevel = UnitLevel("player")
    
    -- Get player spec
    playerSpecID = API.GetActiveSpecID()
    local _, name, _, _, _, role = GetSpecializationInfoByID(playerSpecID)
    playerSpecName = name
    playerRole = role
    
    -- Get player faction
    playerFaction = UnitFactionGroup("player")
    
    -- Get player race
    playerRaceName, playerRace = UnitRace("player")
    
    -- Get covenant ID (only works in Shadowlands)
    if C_Covenants and C_Covenants.GetActiveCovenantID then
        playerCovenantID = C_Covenants.GetActiveCovenantID() or 0
    end
    
    -- Update player items
    API.UpdatePlayerItems()
    
    -- Debug output
    API.PrintDebug(string.format("Player info updated: %s %s (Level %d, Spec %d: %s, Role: %s)",
                playerRaceName, playerClassName, playerLevel, playerSpecID,
                playerSpecName, playerRole))
end

-- Update player items
function API.UpdatePlayerItems()
    -- Clear item table
    playerItems = {}
    
    -- Iterate through all equipment slots
    for i = 1, 16 do
        local itemID = GetInventoryItemID("player", i)
        if itemID then
            local slot = itemSlotNames[i] or ("Slot" .. i)
            playerItems[slot] = itemID
        end
    end
end

-- Register initial events
function API.RegisterInitialEvents()
    -- Register player events
    API.RegisterEvent("PLAYER_ENTERING_WORLD", API.OnPlayerEnteringWorld)
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", API.OnPlayerSpecializationChanged)
    API.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", API.OnPlayerEquipmentChanged)
    API.RegisterEvent("PLAYER_LEVEL_UP", API.OnPlayerLevelChanged)
    
    -- Register combat events
    API.RegisterEvent("PLAYER_REGEN_DISABLED", API.OnPlayerEnterCombat)
    API.RegisterEvent("PLAYER_REGEN_ENABLED", API.OnPlayerLeaveCombat)
    
    -- Register unit events
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", API.OnUnitSpellcastSucceeded)
    API.RegisterEvent("UNIT_SPELLCAST_START", API.OnUnitSpellcastStart)
    API.RegisterEvent("UNIT_SPELLCAST_STOP", API.OnUnitSpellcastStop)
    API.RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", API.OnUnitSpellcastInterrupted)
    
    -- Register health events
    API.RegisterEvent("UNIT_HEALTH", API.OnUnitHealthChanged)
    
    -- Register damage events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", API.OnCombatLogEvent)
    
    -- Register encounter events
    API.RegisterEvent("ENCOUNTER_START", API.OnEncounterStart)
    API.RegisterEvent("ENCOUNTER_END", API.OnEncounterEnd)
    
    -- Register addon events
    API.RegisterEvent("ADDON_LOADED", API.OnAddonLoaded)
end

-- Handler for combat log events
function API.OnCombatLogEvent()
    local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10 = CombatLogGetCurrentEventInfo()
    
    -- Check if the player is the destination (took damage)
    if destGUID == UnitGUID("player") then
        -- Handle damage events
        if subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE" or subEvent == "RANGE_DAMAGE" or subEvent == "SPELL_BUILDING_DAMAGE" then
            local spellID, spellName, spellSchool = param1, param2, param3
            local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = param4, param5, param6, param7, param8, param9, param10
            
            -- Track this damage event
            API.RecordDamageTaken(amount, spellID, spellName, sourceGUID)
        elseif subEvent == "SWING_DAMAGE" then
            local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = param1, param2, param3, param4, param5, param6, param7, param8, param9, param10
            
            -- Track this swing damage
            API.RecordDamageTaken(amount, nil, "Melee", sourceGUID)
        elseif subEvent == "ENVIRONMENTAL_DAMAGE" then
            local environmentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = param1, param2, param3, param4, param5, param6, param7, param8, param9, param10
            
            -- Track environmental damage (fire, lava, etc.)
            API.RecordDamageTaken(amount, nil, "Environment: " .. environmentalType, nil)
        end
    end
end

-- Handler for unit health changed events
function API.OnUnitHealthChanged(unit)
    if unit == "player" then
        -- Update threat level when player health changes
        API.UpdateThreatLevel()
    end
end

-- Handler for encounter start
function API.OnEncounterStart(encounterId, encounterName, difficultyId, groupSize)
    -- Set current encounter
    API.SetCurrentEncounter(encounterId)
    
    -- Initialize defensive tracking for this encounter
    API.InitializeDefensiveTracking()
    
    API.PrintDebug("Encounter started: " .. encounterName .. " (ID: " .. encounterId .. ")")
end

-- Handler for encounter end
function API.OnEncounterEnd(encounterId, encounterName, difficultyId, groupSize, success)
    -- Clear current encounter
    API.SetCurrentEncounter(nil)
    
    API.PrintDebug("Encounter ended: " .. encounterName .. " (Success: " .. (success and "yes" or "no") .. ")")
end

-- Handler for unit spellcast start
function API.OnUnitSpellcastStart(unit, castGUID, spellID)
    -- Track enemy casting for interrupt system
    if UnitCanAttack("player", unit) then
        -- Update target priorities for interrupt system
    elseif UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
        -- Track allied player casts (for coordination)
    end
end

-- Handler for unit spellcast stop
function API.OnUnitSpellcastStop(unit, castGUID, spellID)
    -- Track enemy cast completions
end

-- Handler for unit spellcast interrupted
function API.OnUnitSpellcastInterrupted(unit, castGUID, spellID)
    -- Track successful interrupts
end

-- Register event
function API.RegisterEvent(event, handler)
    -- Create table for event if it doesn't exist
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    
    -- Add handler
    table.insert(eventHandlers[event], handler)
    
    return #eventHandlers[event]
end

-- Unregister event
function API.UnregisterEvent(event, handler)
    -- Check if event exists
    if not eventHandlers[event] then
        return false
    end
    
    -- Find the handler
    for i, func in ipairs(eventHandlers[event]) do
        if func == handler then
            table.remove(eventHandlers[event], i)
            break
        end
    end
    
    -- If no more handlers, unregister event
    if #eventHandlers[event] == 0 then
        eventHandlers[event] = nil
        eventFrame:UnregisterEvent(event)
    end
    
    return true
end

-- Process event
function API.ProcessEvent(event, ...)
    -- Check if we have handlers for this event
    if not eventHandlers[event] then
        return
    end
    
    -- Call all handlers
    for _, handler in ipairs(eventHandlers[event]) do
        -- Use pcall to catch errors
        local success, err = pcall(handler, ...)
        if not success then
            API.PrintError("Error processing event " .. event .. ": " .. tostring(err))
        end
    end
end

-- Event handlers
function API.OnPlayerEnteringWorld()
    -- Update player info
    API.UpdatePlayerInfo()
    
    -- Clear caches
    API.ClearCaches()
    
    -- Update global cooldown
    API.UpdateGlobalCooldown()
end

function API.OnPlayerSpecializationChanged(unit)
    if unit == "player" then
        -- Update player info
        API.UpdatePlayerInfo()
        
        -- Clear spell cache
        API.ClearSpellCache()
    end
end

function API.OnPlayerEquipmentChanged()
    -- Update player items
    API.UpdatePlayerItems()
    
    -- Clear item cache
    API.ClearItemCache()
end

function API.OnPlayerLevelChanged(level)
    -- Update player level
    playerLevel = level
    
    -- Clear spell cache
    API.ClearSpellCache()
end

function API.OnPlayerEnterCombat()
    -- Update player info
    API.UpdatePlayerInfo()
    
    -- Update global cooldown
    API.UpdateGlobalCooldown()
end

function API.OnPlayerLeaveCombat()
    -- Clear caches
    API.ClearCaches()
    
    -- Update spell known cache
    API.UpdateSpellKnownCache()
end

function API.OnUnitSpellcastSucceeded(unit, castGUID, spellID)
    if unit == "player" then
        -- Update global cooldown on player spell cast
        if spellID ~= gcdSpellID then
            API.UpdateGlobalCooldown()
        end
    end
end

function API.OnAddonLoaded(loadedAddonName)
    if loadedAddonName == addonName then
        -- Addon loaded, initialize
        API.PrintDebug("Addon loaded")
    end
end

-- Initialize Tinkr API
function API.InitializeTinkrAPI()
    -- Check if Tinkr is loaded
    if not Tinkr then
        tinkrLoaded = false
        table.insert(loadErrors, "Tinkr not detected. Make sure Tinkr is installed and loaded.")
        API.PrintError("Tinkr not detected. Make sure Tinkr is installed and loaded.")
        return false
    end
    
    -- Check for required Tinkr components
    local missingComponents = {}
    
    -- Check for Tinkr.Secure API
    if not Tinkr.Secure or not Tinkr.Secure.Call then
        table.insert(missingComponents, "Tinkr.Secure.Call")
    end
    
    -- Check for Tinkr.Spell API for spell casting
    if not Tinkr.Spell then
        table.insert(missingComponents, "Tinkr.Spell")
    end
    
    -- Check for Tinkr.Unit API for unit information
    if not Tinkr.Unit then
        table.insert(missingComponents, "Tinkr.Unit")
    end
    
    -- Check for Tinkr.Enemy API for enemy detection
    if not Tinkr.Enemy then
        table.insert(missingComponents, "Tinkr.Enemy")
    end
    
    -- Check for Tinkr.Optimizer API for performance optimization
    if not Tinkr.Optimizer then
        table.insert(missingComponents, "Tinkr.Optimizer")
    end
    
    -- Report missing components if any
    if #missingComponents > 0 then
        local errorMsg = "Missing Tinkr components: " .. table.concat(missingComponents, ", ")
        table.insert(loadErrors, errorMsg)
        API.PrintError(errorMsg)
        API.PrintError("Some features may not work correctly. Please update your Tinkr installation.")
    end
    
    -- Set up Tinkr API
    tinkrLoaded = true
    tinkrAPI = Tinkr
    API.PrintDebug("Tinkr API detected and loaded")
    
    -- Return success status
    return #missingComponents == 0
end

-- Clear caches
function API.ClearCaches()
    API.ClearUnitCache()
    API.ClearSpellCache()
    API.ClearCooldownCache()
    API.ClearItemCache()
end

-- Clear unit cache
function API.ClearUnitCache()
    unitCache = {}
    API.PrintDebug("Unit cache cleared")
end

-- Clear spell cache
function API.ClearSpellCache()
    spellCache = {}
    API.PrintDebug("Spell cache cleared")
end

-- Clear cooldown cache
function API.ClearCooldownCache()
    cooldownCache = {}
    API.PrintDebug("Cooldown cache cleared")
end

-- Clear item cache
function API.ClearItemCache()
    -- We're not implementing a separate item cache yet
    API.PrintDebug("Item cache cleared")
end

-- Update global cooldown
function API.UpdateGlobalCooldown()
    -- Get the GCD value from Tinkr if loaded
    if tinkrLoaded and tinkrAPI.Optimizer then
        globalCooldown = tinkrAPI.Optimizer:GetGCD() or 1.5
    else
        -- Calculate GCD manually
        local haste = UnitSpellHaste("player") / 100
        local gcdBase = 1.5
        local gcdMin = 0.75
        
        globalCooldown = math.max(gcdBase / (1 + haste), gcdMin)
    end
    
    lastGCDUpdate = GetTime()
    API.PrintDebug(string.format("Global Cooldown updated: %.2f seconds", globalCooldown))
end

-- Update spell known cache
function API.UpdateSpellKnownCache()
    -- Only update at specified interval
    if GetTime() - spellKnownRefreshTime < SPELL_KNOWN_REFRESH_INTERVAL then
        return
    end
    
    -- Clear cache
    spellKnown = {}
    
    -- Rebuild cache by checking all known abilities
    if tinkrLoaded and tinkrAPI.Spell then
        -- Use Tinkr's spell list if available
        for spellID, spell in pairs(tinkrAPI.Spell) do
            if type(spellID) == "number" and IsSpellKnown(spellID) then
                spellKnown[spellID] = true
            end
        end
    else
        -- Fallback: Check common abilities for the class
        for spellID, _ in pairs(spellCache) do
            if IsSpellKnown(spellID) then
                spellKnown[spellID] = true
            end
        end
    end
    
    spellKnownRefreshTime = GetTime()
    API.PrintDebug("Spell known cache updated")
end

-- Get player info
function API.GetPlayerInfo()
    return {
        guid = playerGUID,
        class = playerClass,
        className = playerClassName,
        level = playerLevel,
        specID = playerSpecID,
        specName = playerSpecName,
        role = playerRole,
        faction = playerFaction,
        race = playerRace,
        raceName = playerRaceName,
        covenantID = playerCovenantID,
        items = playerItems
    }
end

-- Get active spec ID
function API.GetActiveSpecID()
    if tinkrLoaded and tinkrAPI.Util and tinkrAPI.Util.SpecID then
        -- Use Tinkr's spec ID if available
        return tinkrAPI.Util.SpecID
    else
        -- Fallback to WoW API
        local currentSpec = GetSpecialization()
        if currentSpec then
            return GetSpecializationInfo(currentSpec)
        end
    end
    
    return 0
end

-- Print message
function API.PrintMessage(message)
    print(printPrefix .. message)
end

-- Print error
function API.PrintError(message)
    print(printPrefix .. "|cFFFF0000Error:|r " .. message)
end

-- Print debug
function API.PrintDebug(message)
    if debugMode then
        print(printPrefix .. "|cFF888888Debug:|r " .. message)
    end
end

-- Set addon version
function API.SetAddonVersion(version, build)
    addonVersion = version
    buildNumber = build or buildNumber
    API.PrintDebug("Version set: " .. version .. " (Build " .. buildNumber .. ")")
end

-- Get addon version
function API.GetAddonVersion()
    return addonVersion, buildNumber
end

-- Enable debug mode
function API.EnableDebugMode(enable)
    debugMode = enable
    local status = ""
    if enable then
        status = "enabled"
    else
        status = "disabled"
    end
    API.PrintMessage("Debug mode " .. status)
    return debugMode
end

-- Is debug mode
function API.IsDebugMode()
    return debugMode
end

-- Is tinkr loaded
function API.IsTinkrLoaded()
    return tinkrLoaded
end

-- Determine if a spell needs cursor targeting (ground-targeted or position-targeted)
function API.IsGroundTargetedSpell(spellID)
    -- Table of known ground-targeted spells by class
    local groundTargetedSpells = {
        -- Death Knight
        [43265] = true,   -- Death and Decay
        [49576] = false,  -- Death Grip (position targeted)
        [194679] = true,  -- Rune Tap
        [152280] = true,  -- Defile
        
        -- Demon Hunter
        [198013] = false, -- Eye Beam (cone, not ground targeted)
        [189110] = false, -- Infernal Strike (position targeted)
        [188501] = false, -- Spectral Sight
        [207407] = true,  -- Soul Carver
        
        -- Druid
        [102793] = true,  -- Ursol's Vortex
        [16979] = false,  -- Wild Charge (position targeted)
        [102359] = true,  -- Mass Entanglement
        [88747] = true,   -- Wild Mushroom
        [33917] = false,  -- Mangle
        [102383] = true,  -- Wild Charge (Balance)
        [78674] = false,  -- Starsurge
        [191034] = true,  -- Starfall
        
        -- Hunter
        [194277] = true,  -- Caltrops
        [187698] = true,  -- Tar Trap
        [187650] = true,  -- Freezing Trap
        [1543] = true,    -- Flare
        
        -- Mage
        [190356] = true,  -- Blizzard
        [153626] = true,  -- Arcane Orb
        [157981] = true,  -- Blast Wave
        [122] = false,    -- Frost Nova
        [113724] = true,  -- Ring of Frost
        [31661] = false,  -- Dragon's Breath
        
        -- Monk
        [115315] = true,  -- Summon Black Ox Statue
        [116844] = true,  -- Ring of Peace
        [119381] = false, -- Leg Sweep
        [198898] = true,  -- Song of Chi-Ji
        
        -- Paladin
        [26573] = true,   -- Consecration
        [204035] = true,  -- Hammer of Righteousness
        [114165] = true,  -- Holy Prism
        [200025] = false, -- Beacon of Virtue
        
        -- Priest
        [204263] = true,  -- Shining Force
        [110744] = true,  -- Divine Star
        [120517] = true,  -- Halo
        [32375] = true,   -- Mass Dispel
        [73510] = true,   -- Mind Spike
        
        -- Rogue
        [114018] = false, -- Shroud of Concealment
        [36554] = false,  -- Shadowstep (position targeted)
        [185313] = false, -- Shadow Dance
        [271877] = true,  -- Crimson Tempest
        
        -- Shaman
        [192077] = true,  -- Wind Rush Totem
        [192058] = true,  -- Capacitor Totem
        [108280] = true,  -- Healing Tide Totem
        [51485] = true,   -- Earthgrab Totem
        [192222] = true,  -- Liquid Magma Totem
        [2484] = true,    -- Earthbind Totem
        [73920] = true,   -- Healing Rain
        
        -- Warlock
        [152108] = true,  -- Cataclysm
        [30283] = false,  -- Shadowfury
        [48018] = true,   -- Demonic Circle
        [111771] = true,  -- Demonic Gateway
        [5740] = true,    -- Rain of Fire
        
        -- Warrior
        [118000] = false, -- Dragon Roar
        [46968] = false,  -- Shockwave
        [228920] = false, -- Ravager
        [12975] = false,  -- Last Stand
        [176864] = false, -- Heroic Leap (position targeted)
        [6544] = false,   -- Heroic Leap (position targeted)
        [207682] = false, -- Sigil of Flame
        [202137] = false, -- Sigil of Silence
        [204596] = false, -- Sigil of Flame
        [207684] = false, -- Sigil of Misery
        
        -- Evoker
        [359816] = true,  -- Dream Flight
        [357210] = true,  -- Deep Breath
        [360995] = true   -- Verdant Embrace
    }
    
    -- Table of position-targeted spells (like leaps or charges)
    local positionTargetedSpells = {
        -- Death Knight
        [49576] = true,   -- Death Grip
        
        -- Demon Hunter
        [189110] = true,  -- Infernal Strike
        [195072] = true,  -- Fel Rush
        
        -- Druid
        [16979] = true,   -- Wild Charge
        [102401] = true,  -- Wild Charge (Cat)
        [102383] = true,  -- Wild Charge (Moonkin)
        
        -- Monk
        [115008] = true,  -- Chi Torpedo
        [109132] = true,  -- Roll
        
        -- Rogue
        [36554] = true,   -- Shadowstep
        [195457] = true,  -- Grappling Hook
        
        -- Warrior
        [6544] = true,    -- Heroic Leap
        [100] = true,     -- Charge
        [52174] = true,   -- Heroic Leap
        
        -- Evoker
        [358385] = true,  -- Landslide
        [358267] = true   -- Hover
    }
    
    -- Check if this is a ground-targeted spell
    if groundTargetedSpells[spellID] then
        return true, false
    -- Check if this is a position-targeted spell
    elseif positionTargetedSpells[spellID] then
        return false, true
    end
    
    -- Not a special cursor-targeted spell
    return false, false
end

-- Smart cast function that automatically handles cursor targeting if needed
function API.SmartCast(spellID, unit, mouseover)
    -- Check if this is a special cursor-targeted spell
    local isGroundTargeted, isPositionTargeted = API.IsGroundTargetedSpell(spellID)
    
    -- Check for mouseover targeting if requested
    if mouseover then
        -- Get current mouseover unit and check if it's valid
        local mouseoverUnit = "mouseover"
        if UnitExists(mouseoverUnit) then
            return API.CastSpell(spellID, mouseoverUnit)
        end
        return false
    end
    
    -- Ground targeted spell (AoE)
    if isGroundTargeted then
        return API.CastGroundSpellAuto(spellID)
    -- Position targeted spell (leap/charge)
    elseif isPositionTargeted then
        return API.CastPositionSpellAuto(spellID)
    -- Regular targeted or instant spell
    else
        return API.CastSpell(spellID, unit)
    end
end

-- Cast at mouseover target if available, otherwise fall back to normal target
function API.CastAtMouseover(spellID, fallbackUnit)
    -- Try to cast at mouseover target
    if UnitExists("mouseover") then
        return API.CastSpell(spellID, "mouseover")
    -- Fall back to provided unit if available
    elseif fallbackUnit and UnitExists(fallbackUnit) then
        return API.CastSpell(spellID, fallbackUnit)
    -- Otherwise cast at current target or with no target
    else
        return API.CastSpell(spellID, "target")
    end
end

-- Check if mouseover exists and meets condition
function API.HasMouseover(friendlyOnly, enemyOnly, healthPercent)
    if not UnitExists("mouseover") then
        return false
    end
    
    -- Check if mouseover needs to be friendly
    if friendlyOnly and not UnitIsFriend("player", "mouseover") then
        return false
    end
    
    -- Check if mouseover needs to be enemy
    if enemyOnly and not UnitCanAttack("player", "mouseover") then
        return false
    end
    
    -- Check health threshold if specified
    if healthPercent then
        local _, _, mouseoverHealth = API.GetUnitHealth("mouseover")
        if mouseoverHealth > healthPercent then
            return false
        end
    end
    
    return true
end

-- Get load errors
function API.GetLoadErrors()
    return loadErrors
end

-- Get unit health
function API.GetUnitHealth(unit)
    if not UnitExists(unit) then
        return 0, 0, 0
    end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local healthPercent = maxHealth > 0 and (health / maxHealth * 100) or 0
    
    return health, maxHealth, healthPercent
end

-- Get unit power
function API.GetUnitPower(unit, powerType)
    if not UnitExists(unit) then
        return 0, 0, 0
    end
    
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)
    local powerPercent = maxPower > 0 and (power / maxPower * 100) or 0
    
    return power, maxPower, powerPercent
end

-- Get unit distance
function API.GetUnitDistance(unit)
    -- Use Tinkr if available for accurate distance
    if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
        return tinkrAPI.Unit[unit]:GetDistance() or 999
    else
        -- Fallback: check common range thresholds
        local inRange = IsSpellInRange("Auto Attack", unit) == 1
        if inRange then
            return 5 -- Melee range
        else
            return 999 -- Unknown
        end
    end
end

-- Is unit in range
function API.IsUnitInRange(unit, range)
    local distance = API.GetUnitDistance(unit)
    return distance <= range
end

-- Get enemies in range
function API.GetEnemiesInRange(unit, range)
    local enemies = {}
    
    -- Use Tinkr if available for accurate enemy detection
    if tinkrLoaded and tinkrAPI.Enemy then
        for _, enemy in pairs(tinkrAPI.Enemy) do
            if enemy:GetDistance() <= range then
                table.insert(enemies, enemy.Unit)
            end
        end
    else
        -- Fallback: check target and nameplates
        if UnitExists("target") and UnitCanAttack("player", "target") then
            if API.IsUnitInRange("target", range) then
                table.insert(enemies, "target")
            end
        end
        
        -- Check nameplates if possible
        if C_NamePlate then
            for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
                local unit = nameplate.namePlateUnitToken
                if UnitExists(unit) and UnitCanAttack("player", unit) then
                    if API.IsUnitInRange(unit, range) then
                        table.insert(enemies, unit)
                    end
                end
            end
        end
    end
    
    return enemies
end

-- Get enemy count in range
function API.GetEnemyCount(range)
    return #API.GetEnemiesInRange("player", range)
end

-- Get enemies sorted by various criteria
function API.GetSortedEnemies(range, sortCriteria)
    -- Default to health sorting if not specified
    sortCriteria = sortCriteria or "health"
    
    -- Get all enemies in range
    local enemies = API.GetEnemiesInRange("player", range)
    local sortedEnemies = {}
    
    -- Create a table with enemy data for sorting
    for _, unit in ipairs(enemies) do
        local data = {
            unit = unit,
            health = 0,
            healthPercent = 100,
            distance = API.GetUnitDistance(unit),
            isBoss = UnitClassification(unit) == "worldboss" or UnitClassification(unit) == "rareelite" or UnitClassification(unit) == "elite",
            executePhase = false,
            priority = 0,
            guid = UnitGUID(unit),
            isPlayer = UnitIsPlayer(unit)
        }
        
        -- Get health info
        local health, maxHealth, healthPercent = API.GetUnitHealth(unit)
        data.health = health
        data.healthPercent = healthPercent
        
        -- Check for execute phase (below 20% health)
        if healthPercent < 20 then
            data.executePhase = true
        end
        
        -- Set priority based on unit type
        if UnitClassification(unit) == "worldboss" then
            data.priority = 100
        elseif UnitClassification(unit) == "rareelite" then 
            data.priority = 90
        elseif UnitClassification(unit) == "elite" then
            data.priority = 80
        elseif UnitClassification(unit) == "rare" then
            data.priority = 70
        elseif data.isPlayer then
            data.priority = 85 -- PvP - players are high priority
        else
            data.priority = 50
        end
        
        -- Adjust priority for healers in PvP
        if data.isPlayer then
            local _, unitClass = UnitClass(unit)
            if unitClass == "PRIEST" or unitClass == "DRUID" or unitClass == "MONK" or 
               unitClass == "PALADIN" or unitClass == "SHAMAN" or unitClass == "EVOKER" then
                -- Check if they're casting a heal
                local castInfo = API.GetUnitCastInfo(unit)
                if castInfo and API.IsHealingSpell(castInfo.spellId) then
                    data.priority = data.priority + 50 -- Boost priority for actively healing enemies
                end
            end
        end
        
        -- List of special debuffs that make a target higher priority
        for _, debuffID in ipairs({56222, 45524, 702, 115196, 118, 34914, 980, 262115, 316099}) do
            if API.UnitHasDebuff(unit, debuffID, "player") then
                data.priority = data.priority + 10 -- Boost priority for targets with our debuffs
                break
            end
        end
        
        -- Adjust priority based on health (execute phase)
        if data.executePhase then
            data.priority = data.priority + 30
        end
        
        table.insert(sortedEnemies, data)
    end
    
    -- Sort the enemies based on the specified criteria
    if sortCriteria == "health" then
        table.sort(sortedEnemies, function(a, b) return a.health < b.health end)
    elseif sortCriteria == "healthpercent" then
        table.sort(sortedEnemies, function(a, b) return a.healthPercent < b.healthPercent end)
    elseif sortCriteria == "distance" then
        table.sort(sortedEnemies, function(a, b) return a.distance < b.distance end)
    elseif sortCriteria == "priority" then
        table.sort(sortedEnemies, function(a, b) return a.priority > b.priority end)
    end
    
    -- Return the sorted list of enemy units
    local result = {}
    for _, data in ipairs(sortedEnemies) do
        table.insert(result, data.unit)
    end
    
    return result
end

-- Find the best target based on multiple criteria
function API.FindBestTarget(range, preferExecute, requireDot, requireDebuff, specificUnit)
    -- If specific unit is requested and exists, use it
    if specificUnit and UnitExists(specificUnit) then
        return specificUnit
    end
    
    -- Current target is valid and meets conditions
    if UnitExists("target") and UnitCanAttack("player", "target") and 
       API.IsUnitInRange("target", range) then
        
        local _, _, healthPercent = API.GetUnitHealth("target")
        
        -- If we prefer execute phase and target is in execute phase, keep it
        if preferExecute and healthPercent < 20 then
            return "target"
        end
        
        -- If we require DoT and target has our DoT, keep it
        if requireDot then
            for _, dotID in ipairs(requireDot) do
                if API.UnitHasDebuff("target", dotID, "player") then
                    return "target"
                end
            end
        end
        
        -- If we require specific debuff and target has it, keep it
        if requireDebuff then
            for _, debuffID in ipairs(requireDebuff) do
                if API.UnitHasDebuff("target", debuffID) then
                    return "target"
                end
            end
        end
    end
    
    -- Get all potential targets sorted by priority
    local potentialTargets = API.GetSortedEnemies(range, "priority")
    
    -- No targets in range
    if #potentialTargets == 0 then
        return nil
    end
    
    -- Filter based on requirements
    local filteredTargets = {}
    
    for _, unit in ipairs(potentialTargets) do
        local valid = true
        
        -- Check for execute phase requirement
        if preferExecute then
            local _, _, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < 20 then
                -- This is an execute target, add immediately
                table.insert(filteredTargets, unit)
                -- If we just need any execute target, return first one
                if true then -- preferExecute == "any" (can add different execute behaviors)
                    return unit
                end
            end
        end
        
        -- Check for DoT requirement
        if requireDot and valid then
            local hasDot = false
            for _, dotID in ipairs(requireDot) do
                if API.UnitHasDebuff(unit, dotID, "player") then
                    hasDot = true
                    break
                end
            end
            valid = hasDot
        end
        
        -- Check for debuff requirement
        if requireDebuff and valid then
            local hasDebuff = false
            for _, debuffID in ipairs(requireDebuff) do
                if API.UnitHasDebuff(unit, debuffID) then
                    hasDebuff = true
                    break
                end
            end
            valid = hasDebuff
        end
        
        if valid then
            table.insert(filteredTargets, unit)
        end
    end
    
    -- If we found no valid targets with our filters, just return the highest priority target
    if #filteredTargets == 0 then
        return potentialTargets[1]
    end
    
    -- Return the best filtered target
    return filteredTargets[1]
end

-- Switch to best target if current one isn't ideal
function API.SwitchToBestTarget(range, preferExecute, requireDot, requireDebuff)
    local bestTarget = API.FindBestTarget(range, preferExecute, requireDot, requireDebuff)
    
    -- If we found a target and it's different from current target
    if bestTarget and (not UnitExists("target") or not UnitIsUnit("target", bestTarget)) then
        -- Use Tinkr if available
        if tinkrLoaded and tinkrAPI.Secure and tinkrAPI.Secure.Call then
            return tinkrAPI.Secure.Call("TargetUnit", bestTarget)
        else
            return TargetUnit(bestTarget)
        end
    end
    
    return false
end

-- Check if a spell is a healing spell
function API.IsHealingSpell(spellID)
    -- Table of common healing spells across all classes
    local healingSpells = {
        -- Priest
        [2050] = true,   -- Holy Word: Serenity
        [2061] = true,   -- Flash Heal
        [596] = true,    -- Prayer of Healing
        [32546] = true,  -- Binding Heal
        [33076] = true,  -- Prayer of Mending
        [47540] = true,  -- Penance (Discipline)
        
        -- Paladin
        [82326] = true,  -- Holy Light
        [19750] = true,  -- Flash of Light
        [633] = true,    -- Lay on Hands
        [85222] = true,  -- Light of Dawn
        [20473] = true,  -- Holy Shock
        
        -- Druid
        [774] = true,    -- Rejuvenation
        [8936] = true,   -- Regrowth
        [33763] = true,  -- Lifebloom
        [48438] = true,  -- Wild Growth
        [18562] = true,  -- Swiftmend
        
        -- Shaman
        [8004] = true,   -- Healing Surge
        [1064] = true,   -- Chain Heal
        [61295] = true,  -- Riptide
        [73920] = true,  -- Healing Rain
        [77472] = true,  -- Healing Wave
        
        -- Monk
        [115175] = true, -- Soothing Mist
        [116670] = true, -- Vivify
        [115151] = true, -- Renewing Mist
        [116849] = true, -- Life Cocoon
        [124682] = true, -- Enveloping Mist
        
        -- Evoker
        [361469] = true, -- Living Flame (healing)
        [367230] = true, -- Spiritbloom
        [355936] = true, -- Dream Breath
        [366155] = true, -- Reversion
        [364343] = true, -- Echo
        
        -- Misc/Other
        [2060] = true,   -- Heal (Priest)
        [32546] = true,  -- Binding Heal (Priest)
    }
    
    return healingSpells[spellID] == true
end

-- Enemy classification system - classify an enemy unit based on various attributes
function API.ClassifyEnemy(unit)
    if not UnitExists(unit) then
        return "unknown", 0
    end
    
    local classification = {
        type = "normal",      -- normal, elite, rare, boss, raidBoss, pvp, healer, highValue
        priority = 50,        -- 0-100 scale, higher = more important
        classification = "",  -- WoW classification string
        isTanking = false,    -- Is tanking the player/group
        isCasting = false,    -- Is casting something
        isDangerous = false,  -- Is doing something dangerous
        inExecute = false,    -- Is in execute range
        healthPct = 100,      -- Health percentage
        distance = 999,       -- Distance to player
        guid = UnitGUID(unit),
        marker = GetRaidTargetIndex(unit) or 0, -- Raid marker (skull, cross, etc)
        buffs = {},           -- Important buffs
        debuffs = {}          -- Important debuffs
    }
    
    -- Get basic info
    local _, _, healthPct = API.GetUnitHealth(unit)
    classification.healthPct = healthPct
    classification.distance = API.GetUnitDistance(unit)
    classification.classification = UnitClassification(unit)
    
    -- Check raid marker
    if classification.marker > 0 then
        -- Adjust priority based on raid marker
        if classification.marker == 8 then      -- Skull
            classification.priority = classification.priority + 40
            classification.type = "highValue"
        elseif classification.marker == 7 then  -- Cross
            classification.priority = classification.priority + 30
        elseif classification.marker == 6 then  -- Square
            classification.priority = classification.priority + 20
        elseif classification.marker == 1 then  -- Star
            classification.priority = classification.priority + 25
        else
            classification.priority = classification.priority + 10
        end
    end
    
    -- Check unit classification from WoW
    if UnitClassification(unit) == "worldboss" then
        classification.type = "raidBoss"
        classification.priority = 100
    elseif UnitClassification(unit) == "rareelite" then
        classification.type = "rare"
        classification.priority = 90
    elseif UnitClassification(unit) == "elite" then
        classification.type = "elite"
        classification.priority = 85
    elseif UnitClassification(unit) == "rare" then
        classification.type = "rare"
        classification.priority = 80
    end
    
    -- Check if it's a player (PvP)
    if UnitIsPlayer(unit) then
        classification.type = "pvp"
        classification.priority = 85
        
        -- Check if it's a healer
        local _, class = UnitClass(unit)
        if class == "PRIEST" or class == "DRUID" or class == "MONK" or 
           class == "PALADIN" or class == "SHAMAN" or class == "EVOKER" then
            -- Check if they're casting a heal
            local castInfo = API.GetUnitCastInfo(unit)
            if castInfo and API.IsHealingSpell(castInfo.spellId) then
                classification.type = "healer"
                classification.priority = 95
                classification.isDangerous = true
            end
        end
    end
    
    -- Check if unit is in execute range
    if healthPct < 20 then
        classification.inExecute = true
        classification.priority = classification.priority + 20
    end
    
    -- Check if casting
    local castInfo = API.GetUnitCastInfo(unit)
    if castInfo then
        classification.isCasting = true
        
        -- Check if casting something dangerous
        if API.IsHighPriorityInterrupt(castInfo.spellId) then
            classification.isDangerous = true
            classification.priority = classification.priority + 25
        end
    end
    
    -- Check if tanking
    if UnitThreatSituation("player", unit) and UnitThreatSituation("player", unit) >= 2 then
        classification.isTanking = true
        classification.priority = classification.priority + 15
    end
    
    -- Check for important auras
    -- Buffs that make an enemy more dangerous
    local dangerousBuffs = {
        [31884] = true,  -- Avenging Wrath
        [51271] = true,  -- Pillar of Frost
        [190319] = true, -- Combustion
        [121471] = true, -- Shadow Blades
        [1719] = true,   -- Recklessness
        [194223] = true, -- Celestial Alignment
        [13750] = true,  -- Adrenaline Rush
        [102560] = true  -- Incarnation: Chosen of Elune
    }
    
    for buffID, _ in pairs(dangerousBuffs) do
        local hasBuff = API.UnitHasBuff(unit, buffID)
        if hasBuff then
            classification.buffs[buffID] = true
            classification.isDangerous = true
            classification.priority = classification.priority + 15
        end
    end
    
    -- Return the classification type and priority
    return classification.type, classification.priority, classification
end

-- Is high priority spell to interrupt
function API.IsHighPriorityInterrupt(spellID)
    -- Table of dangerous spells that should be interrupted with high priority
    local highPrioritySpells = {
        -- Healing spells
        [2060] = true,   -- Heal (Priest)
        [2061] = true,   -- Flash Heal
        [8936] = true,   -- Regrowth
        [19750] = true,  -- Flash of Light
        [8004] = true,   -- Healing Surge
        [73920] = true,  -- Healing Rain
        [116670] = true, -- Vivify
        
        -- Dangerous damage spells
        [191823] = true, -- Furious Blast
        [200248] = true, -- Arcane Bolt
        [398150] = true, -- Runecarver's Deathtouch
        [377004] = true, -- Deafening Screech
        [388862] = true, -- Searing Blow
        [387564] = true, -- Mystic Blast
        [387145] = true, -- Frost Shock
        [374544] = true, -- Soul Cleave
        [387411] = true, -- Death Bolt
        [396812] = true, -- Molten Boulder
        [388925] = true, -- Seismic Slam
        [373932] = true, -- Vital Rupture
        [397892] = true, -- Scintillating Frost
        [377348] = true, -- Eternity Zone
        [386019] = true, -- Wildfire
        
        -- CC spells
        [20066] = true,  -- Repentance
        [115078] = true, -- Paralysis
        [118] = true,    -- Polymorph
        [51514] = true,  -- Hex
        [211015] = true, -- Face Palm
        [710] = true,    -- Banish
        [5782] = true,   -- Fear
        [10326] = true,  -- Turn Evil
        
        -- Summoning spells
        [30146] = true,  -- Summon Imp
        [697] = true,    -- Summon Voidwalker
        [23789] = true,  -- Summon Dreadsteed
        
        -- Misc high threat spells
        [32375] = true,  -- Mass Dispel
        [64901] = true,  -- Symbol of Hope
        [15286] = true,  -- Vampiric Embrace
        [64843] = true,  -- Divine Hymn
        [108281] = true, -- Ancestral Guidance
        [204437] = true, -- Lightning Lasso
    }
    
    -- If the spell is a healing spell, automatically consider it high priority
    if API.IsHealingSpell(spellID) then
        return true
    end
    
    return highPrioritySpells[spellID] == true
end

-- Get the next interrupt target (for coordinating interrupts in a group)
function API.GetInterruptTarget(range, ownInterruptOnly)
    local interruptTargets = {}
    local interruptableUnits = {}
    
    -- Check all enemies in range
    local enemies = API.GetEnemiesInRange("player", range)
    for _, unit in ipairs(enemies) do
        local castInfo = API.GetUnitCastInfo(unit)
        
        -- Target is casting and cast is interruptible
        if castInfo and castInfo.interruptible then
            local priority = 1
            
            -- Set priority based on spell
            if API.IsHighPriorityInterrupt(castInfo.spellId) then
                priority = 100  -- High priority spells
            elseif API.IsHealingSpell(castInfo.spellId) then
                priority = 90   -- Any healing spell
            elseif castInfo.remaining < 0.5 then
                priority = 80   -- About to finish casting
            elseif UnitIsPlayer(unit) then
                priority = 70   -- Player casts are generally important
            end
            
            -- Adjust for target's health (lower health = higher priority)
            local _, _, healthPercent = API.GetUnitHealth(unit)
            if healthPercent < 30 then
                priority = priority + 15  -- Low health enemy (likely a kill target)
            end
            
            -- Adjust for cast time remaining
            local timeRemaining = castInfo.remaining
            if timeRemaining < 1.0 then
                priority = priority + 25  -- About to complete cast, higher priority
            end
            
            -- Store the unit and its priority
            table.insert(interruptTargets, {
                unit = unit,
                spellId = castInfo.spellId,
                spellName = castInfo.name,
                priority = priority,
                timeRemaining = timeRemaining
            })
        end
    end
    
    -- If no interruptible targets found
    if #interruptTargets == 0 then
        return nil
    end
    
    -- Sort by priority (highest first)
    table.sort(interruptTargets, function(a, b)
        return a.priority > b.priority
    end)
    
    -- Return the highest priority target
    return interruptTargets[1].unit, interruptTargets[1].spellId, interruptTargets[1].spellName
end

-- Try to interrupt a target using available interrupt abilities
function API.TryInterrupt(range, interruptSpells)
    -- Only process if we have interrupt spells
    if not interruptSpells or #interruptSpells == 0 then
        return false
    end
    
    -- Get the best target to interrupt
    local interruptTarget, spellId, spellName = API.GetInterruptTarget(range)
    if not interruptTarget then
        return false
    end
    
    -- Try each interrupt ability in order
    for _, interruptData in ipairs(interruptSpells) do
        local spellID = interruptData.spellId
        local dispellable = interruptData.dispel or false  -- Some interrupts can only hit certain spell schools
        
        -- Skip if spell is on cooldown or not usable
        if not API.IsSpellUsable(spellID) then
            goto continue
        end
        
        -- Cast the interrupt spell at the target
        if API.CastSpell(spellID, interruptTarget) then
            API.PrintDebug("Interrupting " .. (spellName or "Unknown Spell") .. " on " .. interruptTarget)
            return true
        end
        
        ::continue::
    end
    
    return false
end

-- Check if a spell can be interrupted by this player
function API.CanInterruptSpell(spellID)
    -- Table of spells that cannot be interrupted
    local uninterruptibleSpells = {
        -- Raid boss abilities
        [17651] = true,   -- Iron Fury
        [99526] = true,   -- Ka Boom!
        [143343] = true,  -- Deafening Screech
        [106523] = true,  -- Cataclysm
        [74367] = true,   -- Fury of the Darkened Sky
        
        -- Dungeon boss abilities
        [398206] = true,  -- Absolute Zero
        [397881] = true,  -- Oceanic Tempest
        [407796] = true,  -- Frostbomb Detonation
        [410904] = true,  -- Expulsion
        [378282] = true,  -- Earthfury
        
        -- Special enemy abilities
        [19615] = true,   -- Frenzy
        [31616] = true,   -- Nature Channeling
        [46190] = true,   -- Shadow Channeling
        
        -- Raid mechanics
        [144922] = true,  -- Manifest Rage
        [235597] = true,  -- Annihilation
    }
    
    return not uninterruptibleSpells[spellID]
end

-- Encounter-specific logic system
local encounterRegistry = {}
local currentEncounterId = 0
local inEncounter = false
local encounterStartTime = 0
local encounterPhase = 1

-- Register encounter data
function API.RegisterEncounter(encounterId, encounterData)
    encounterRegistry[encounterId] = encounterData
    API.PrintDebug("Registered encounter: " .. encounterData.name)
end

-- Set current encounter
function API.SetCurrentEncounter(encounterId)
    if encounterId and encounterRegistry[encounterId] then
        currentEncounterId = encounterId
        inEncounter = true
        encounterStartTime = GetTime()
        encounterPhase = 1
        API.PrintDebug("Set current encounter: " .. encounterRegistry[encounterId].name)
        return true
    else
        -- Clear current encounter
        currentEncounterId = 0
        inEncounter = false
        encounterStartTime = 0
        encounterPhase = 1
        API.PrintDebug("Cleared current encounter")
        return false
    end
end

-- Get current encounter
function API.GetCurrentEncounter()
    if inEncounter and currentEncounterId > 0 then
        local encounterData = encounterRegistry[currentEncounterId]
        if encounterData then
            return encounterData.id, encounterData, encounterPhase, GetTime() - encounterStartTime
        end
    end
    return nil, nil, 0, 0
end

-- Update encounter phase
function API.UpdateEncounterPhase(newPhase)
    if inEncounter and currentEncounterId > 0 then
        encounterPhase = newPhase
        API.PrintDebug("Updated encounter phase to " .. newPhase)
        return true
    end
    return false
end

-- Get encounter-specific target
function API.GetEncounterTarget(role)
    if not inEncounter or currentEncounterId == 0 then
        return nil
    end
    
    local encounter = encounterRegistry[currentEncounterId]
    if not encounter then
        return nil
    end
    
    -- Check if there's a phase-specific target
    if encounter.phases and encounter.phases[encounterPhase] and encounter.phases[encounterPhase].targets then
        local phaseTargets = encounter.phases[encounterPhase].targets
        
        -- Get role-specific target if available
        if role and phaseTargets[role] then
            return phaseTargets[role]
        end
        
        -- Otherwise get default target for this phase
        if phaseTargets.default then
            return phaseTargets.default
        end
    end
    
    -- Fall back to encounter-level targets
    if encounter.targets then
        -- Get role-specific target if available
        if role and encounter.targets[role] then
            return encounter.targets[role]
        end
        
        -- Otherwise get default target
        if encounter.targets.default then
            return encounter.targets.default
        end
    end
    
    return nil
end

-- Should use ability in current encounter
function API.ShouldUseAbilityInEncounter(spellID, targetUnit)
    if not inEncounter or currentEncounterId == 0 then
        return true -- No encounter-specific rules, so allow ability
    end
    
    local encounter = encounterRegistry[currentEncounterId]
    if not encounter then
        return true -- No encounter data, so allow ability
    end
    
    -- Check if there are encounter-specific ability rules
    if encounter.abilities and encounter.abilities[spellID] then
        local abilityRules = encounter.abilities[spellID]
        
        -- Check if we're in a restricted phase
        if abilityRules.restrictPhases then
            local phaseAllowed = false
            for _, phase in ipairs(abilityRules.restrictPhases) do
                if phase == encounterPhase then
                    phaseAllowed = true
                    break
                end
            end
            
            if not phaseAllowed then
                return false -- This ability is restricted in the current phase
            end
        end
        
        -- Check for required targets
        if abilityRules.requiredTargets and targetUnit then
            local targetGUID = UnitGUID(targetUnit)
            if targetGUID then
                local targetAllowed = false
                for _, targetId in ipairs(abilityRules.requiredTargets) do
                    -- Check if the target's NPC ID matches
                    local targetNpcId = tonumber(targetGUID:match("Creature%-0%-%d+%-%d+%-%d+%-(%d+)"))
                    if targetNpcId and targetNpcId == targetId then
                        targetAllowed = true
                        break
                    end
                end
                
                if not targetAllowed then
                    return false -- This ability is not allowed on this target
                end
            end
        end
        
        -- Special case handling for this ability
        if abilityRules.customHandler and type(abilityRules.customHandler) == "function" then
            return abilityRules.customHandler(targetUnit, encounterPhase)
        end
    end
    
    -- No restrictions found, allow the ability
    return true
end

-- Register common raid and dungeon encounters
function API.RegisterCommonEncounters()
    -- Raid: Amirdrassil, the Dream's Hope
    API.RegisterEncounter(2564, { -- Gnarlroot
        id = 2564,
        name = "Gnarlroot",
        type = "raid",
        phases = {
            [1] = { -- Phase 1
                startAt = 0,
                targets = {
                    default = "boss1"
                }
            },
            [2] = { -- Phase 2 (add phase)
                targets = {
                    dps = "priority", -- Target the highest priority add
                    healer = "boss1",
                    tank = "boss1"
                }
            }
        },
        abilities = {
            [5246] = { -- Intimidating Shout
                restrictPhases = {2}, -- Only use in phase 2
                customHandler = function(target, phase)
                    -- Only use if there are 3+ adds
                    return API.GetEnemyCount(8) >= 3
                end
            }
        }
    })
    
    API.RegisterEncounter(2563, { -- Igira the Cruel
        id = 2563,
        name = "Igira the Cruel",
        type = "raid",
        phases = {
            [1] = { -- Phase 1
                startAt = 0
            },
            [2] = { -- Phase 2
                targets = {
                    dps = "boss1",
                    healer = "boss1",
                    tank = "boss1"
                }
            },
            [3] = { -- Phase 3
                abilities = {
                    [6673] = { -- Battle Shout
                        restrictPhases = {3} -- Only use in phase 3
                    }
                }
            }
        }
    })
    
    -- Dungeon: Dawn of the Infinite
    API.RegisterEncounter(2528, { -- Chrono-Lord Deios
        id = 2528,
        name = "Chrono-Lord Deios",
        type = "dungeon",
        phases = {
            [1] = { -- Phase 1
                startAt = 0,
                targets = {
                    default = "boss1"
                }
            },
            [2] = { -- Intermission
                targets = {
                    dps = "priority", -- Target the highest priority add
                    healer = "boss1",
                    tank = "boss1"
                }
            }
        },
        abilities = {
            [383067] = { -- Massive Slam
                restrictPhases = {1}, -- Only use in phase 1
            }
        }
    })
end

-- Smart Defensive System
-- Track incoming damage
local damageHistory = {}
local damageBySpellID = {}
local lastDamageTime = 0
local recentDamageWindow = 5 -- How many seconds to consider recent damage
local recentDamageTaken = 0
local totalHealthLost = 0
local damageSpikes = {}
local maxDamageSpikes = 10
local lastHealthPct = 100
local isInDanger = false
local currentThreatLevel = 0 -- 0-100 scale

-- Initialize defensive tracking
function API.InitializeDefensiveTracking()
    damageHistory = {}
    damageBySpellID = {}
    lastDamageTime = GetTime()
    recentDamageTaken = 0
    totalHealthLost = 0
    damageSpikes = {}
    lastHealthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    isInDanger = false
    currentThreatLevel = 0
    
    API.PrintDebug("Defensive tracking initialized")
end

-- Record damage taken
function API.RecordDamageTaken(amount, spellID, spellName, sourceGUID)
    local now = GetTime()
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Record this damage event
    local damageEvent = {
        time = now,
        amount = amount,
        spellID = spellID,
        spellName = spellName,
        sourceGUID = sourceGUID,
        healthPct = healthPct
    }
    
    -- Add to history
    table.insert(damageHistory, damageEvent)
    
    -- Limit history size
    if #damageHistory > 100 then
        table.remove(damageHistory, 1)
    end
    
    -- Track damage by spell
    if spellID then
        if not damageBySpellID[spellID] then
            damageBySpellID[spellID] = {
                total = 0,
                count = 0,
                lastTime = 0,
                name = spellName,
                sources = {}
            }
        end
        
        damageBySpellID[spellID].total = damageBySpellID[spellID].total + amount
        damageBySpellID[spellID].count = damageBySpellID[spellID].count + 1
        damageBySpellID[spellID].lastTime = now
        
        -- Track damage source
        if sourceGUID then
            if not damageBySpellID[spellID].sources[sourceGUID] then
                damageBySpellID[spellID].sources[sourceGUID] = {
                    total = 0,
                    count = 0
                }
            end
            
            damageBySpellID[spellID].sources[sourceGUID].total = damageBySpellID[spellID].sources[sourceGUID].total + amount
            damageBySpellID[spellID].sources[sourceGUID].count = damageBySpellID[spellID].sources[sourceGUID].count + 1
        end
    end
    
    -- Update recent damage
    recentDamageTaken = recentDamageTaken + amount
    
    -- Detect damage spike
    local healthDropPct = lastHealthPct - healthPct
    if healthDropPct > 15 then
        -- Record this as a damage spike
        local spike = {
            time = now,
            amount = amount,
            spellID = spellID,
            healthDropPct = healthDropPct,
            healthPct = healthPct
        }
        
        table.insert(damageSpikes, spike)
        
        -- Limit damage spikes history
        if #damageSpikes > maxDamageSpikes then
            table.remove(damageSpikes, 1)
        end
        
        -- Set danger state
        isInDanger = true
    end
    
    -- Update last values
    lastDamageTime = now
    lastHealthPct = healthPct
    totalHealthLost = totalHealthLost + amount
    
    -- Update threat level
    API.UpdateThreatLevel()
end

-- Update threat level
function API.UpdateThreatLevel()
    local now = GetTime()
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Base threat on current health
    local healthThreat = 0
    if healthPct < 25 then
        healthThreat = 80
    elseif healthPct < 40 then
        healthThreat = 60
    elseif healthPct < 60 then
        healthThreat = 40
    elseif healthPct < 75 then
        healthThreat = 20
    end
    
    -- Adjust for recent damage
    local recentDamageThreat = 0
    local recentDamage = API.GetRecentDamageTaken(3) -- Damage in last 3 seconds
    local playerMaxHealth = UnitHealthMax("player")
    
    if recentDamage > playerMaxHealth * 0.3 then
        recentDamageThreat = 80
    elseif recentDamage > playerMaxHealth * 0.2 then
        recentDamageThreat = 60
    elseif recentDamage > playerMaxHealth * 0.1 then
        recentDamageThreat = 40
    elseif recentDamage > playerMaxHealth * 0.05 then
        recentDamageThreat = 20
    end
    
    -- Adjust for damage spikes
    local spikeThreat = 0
    if #damageSpikes > 0 then
        local mostRecentSpike = damageSpikes[#damageSpikes]
        if mostRecentSpike.time > now - 4 then
            -- Recent spike
            if mostRecentSpike.healthDropPct > 30 then
                spikeThreat = 100
            elseif mostRecentSpike.healthDropPct > 20 then
                spikeThreat = 80
            else
                spikeThreat = 60
            end
        end
    end
    
    -- Adjust for enemy count
    local enemyCountThreat = 0
    local enemyCount = API.GetEnemyCount(8)
    if enemyCount > 5 then
        enemyCountThreat = 40
    elseif enemyCount > 3 then
        enemyCountThreat = 20
    end
    
    -- Adjust for being in a boss encounter
    local encounterThreat = 0
    if inEncounter and currentEncounterId > 0 then
        encounterThreat = 20
    end
    
    -- Calculate final threat
    currentThreatLevel = math.max(healthThreat, recentDamageThreat, spikeThreat, enemyCountThreat, encounterThreat)
    
    -- Reset danger state if threat is low
    if currentThreatLevel < 20 and isInDanger then
        isInDanger = false
    end
end

-- Get recent damage taken
function API.GetRecentDamageTaken(seconds)
    seconds = seconds or recentDamageWindow
    local now = GetTime()
    local total = 0
    
    for _, event in ipairs(damageHistory) do
        if event.time > now - seconds then
            total = total + event.amount
        end
    end
    
    return total
end

-- Get current threat level
function API.GetThreatLevel()
    return currentThreatLevel, isInDanger
end

-- Should use defensive cooldown
function API.ShouldUseDefensive(defensiveType, minThreatLevel, minHealthPct, maxHealthPct)
    -- Default values
    minThreatLevel = minThreatLevel or 50
    minHealthPct = minHealthPct or 0
    maxHealthPct = maxHealthPct or 100
    
    -- Get current state
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Check health percentage range
    if healthPct < minHealthPct or healthPct > maxHealthPct then
        return false
    end
    
    -- Check threat level
    if currentThreatLevel < minThreatLevel then
        return false
    end
    
    -- Additional checks based on defensive type
    if defensiveType == "emergency" then
        -- Emergency defensives (like Last Stand, Divine Shield)
        return healthPct < 30 or (isInDanger and currentThreatLevel >= 80)
    elseif defensiveType == "major" then
        -- Major defensives (like Shield Wall, Icebound Fortitude)
        return healthPct < 50 or (isInDanger and currentThreatLevel >= 60)
    elseif defensiveType == "minor" then
        -- Minor defensives (like Frenzied Regeneration, Ignore Pain)
        return healthPct < 75 or currentThreatLevel >= 40
    elseif defensiveType == "aoe" then
        -- AoE defensives (like Anti-Magic Zone, Rallying Cry)
        return API.GetEnemyCount(8) >= 3 or currentThreatLevel >= 50
    elseif defensiveType == "immunity" then
        -- Immunity effects (like Divine Shield, Ice Block)
        return healthPct < 15 or (isInDanger and currentThreatLevel >= 90)
    end
    
    -- Default to using the defensive if no specific type matched
    return true
end

-- Use smart defensive
function API.UseSmartDefensive(defensiveSpells)
    -- Check if we have defensive spells
    if not defensiveSpells or #defensiveSpells == 0 then
        return false
    end
    
    -- Try each defensive ability in order
    for _, defensiveData in ipairs(defensiveSpells) do
        local spellID = defensiveData.spellId
        local defType = defensiveData.type or "minor"
        local minThreat = defensiveData.minThreat or 50
        local minHealth = defensiveData.minHealth or 0
        local maxHealth = defensiveData.maxHealth or 100
        
        -- Skip if spell is on cooldown or not usable
        if not API.IsSpellUsable(spellID) then
            goto continue
        end
        
        -- Check if we should use this defensive
        if API.ShouldUseDefensive(defType, minThreat, minHealth, maxHealth) then
            -- Cast the defensive spell
            if API.CastSpell(spellID) then
                API.PrintDebug("Using " .. defType .. " defensive: " .. GetSpellInfo(spellID))
                return true
            end
        end
        
        ::continue::
    end
    
    return false
end

-- Get best AoE position
function API.GetBestAoEPosition(radius)
    -- Default radius if not specified
    radius = radius or 8
    
    -- No Tinkr available, can't determine best position
    if not tinkrLoaded or not tinkrAPI.Unit or not tinkrAPI.Unit["player"] or not tinkrAPI.Enemy then
        return nil, nil, nil
    end
    
    -- Get player position as reference
    local px, py, pz = tinkrAPI.Unit["player"]:GetPosition()
    if not px or not py or not pz then
        return nil, nil, nil
    end
    
    -- Get all enemies
    local enemies = {}
    for _, enemy in pairs(tinkrAPI.Enemy) do
        -- Only consider enemies within reasonable casting distance
        if enemy:GetDistance() <= 40 then
            local ex, ey, ez = enemy:GetPosition()
            if ex and ey and ez then
                table.insert(enemies, {unit = enemy.Unit, x = ex, y = ey, z = ez})
            end
        end
    end
    
    -- Not enough enemies for AoE
    if #enemies < 2 then
        -- If we have at least one enemy, return its position
        if #enemies == 1 then
            return enemies[1].x, enemies[1].y, enemies[1].z
        end
        return nil, nil, nil
    end
    
    -- Find the position that affects the most enemies
    local bestScore = 0
    local bestX, bestY, bestZ = nil, nil, nil
    
    -- Try using each enemy position as a potential center
    for _, centerEnemy in ipairs(enemies) do
        local cx, cy, cz = centerEnemy.x, centerEnemy.y, centerEnemy.z
        local score = 0
        
        -- Count how many enemies would be hit from this position
        for _, targetEnemy in ipairs(enemies) do
            local distance = math.sqrt((targetEnemy.x - cx)^2 + (targetEnemy.y - cy)^2 + (targetEnemy.z - cz)^2)
            if distance <= radius then
                -- Add to score, with diminishing value based on distance from player
                local playerDistance = math.sqrt((cx - px)^2 + (cy - py)^2 + (cz - pz)^2)
                local distanceFactor = math.max(0.1, 1 - (playerDistance / 40))
                score = score + distanceFactor
            end
        end
        
        -- Check if this is the best position so far
        if score > bestScore then
            bestScore = score
            bestX, bestY, bestZ = cx, cy, cz
        end
    end
    
    -- If no good position found, try player's target as fallback
    if not bestX and UnitExists("target") and tinkrAPI.Unit["target"] then
        local tx, ty, tz = tinkrAPI.Unit["target"]:GetPosition()
        if tx and ty and tz then
            bestX, bestY, bestZ = tx, ty, tz
        end
    end
    
    return bestX, bestY, bestZ
end

-- Get spell cooldown
function API.GetSpellCooldown(spellID)
    -- Check cooldown cache
    local now = GetTime()
    if cooldownCache[spellID] and cooldownCache[spellID].expirationTime > now then
        return cooldownCache[spellID].cooldown, cooldownCache[spellID].expirationTime - now
    end
    
    -- Get cooldown from Tinkr if available
    if tinkrLoaded and tinkrAPI.Spell then
        local spell = tinkrAPI.Spell[spellID]
        if spell then
            local cd, remaining = spell:GetCooldown()
            
            -- Cache for a short time
            cooldownCache[spellID] = {
                cooldown = cd,
                remaining = remaining,
                expirationTime = now + 0.1
            }
            
            return cd, remaining
        end
    end
    
    -- Fallback to WoW API
    local start, duration, enabled = GetSpellCooldown(spellID)
    if start and duration then
        local remaining = (start + duration) - now
        if remaining < 0 then
            remaining = 0
        end
        
        -- Cache for a short time
        cooldownCache[spellID] = {
            cooldown = duration,
            remaining = remaining,
            expirationTime = now + 0.1
        }
        
        return duration, remaining
    end
    
    return 0, 0
end

-- Is spell usable
function API.IsSpellUsable(spellID)
    -- Check if spell is known
    if not API.IsSpellKnown(spellID) then
        return false
    end
    
    -- Check if spell is on cooldown
    local _, remaining = API.GetSpellCooldown(spellID)
    if remaining > 0 then
        return false
    end
    
    -- Check if spell is usable (mana, resources, etc)
    local usable, noMana = IsUsableSpell(spellID)
    if not usable then
        return false
    end
    
    return true
end

-- Is spell known
function API.IsSpellKnown(spellID)
    -- Check cache
    if spellKnown[spellID] ~= nil then
        return spellKnown[spellID]
    end
    
    -- Check if spell is known
    local isKnown = IsSpellKnown(spellID)
    spellKnown[spellID] = isKnown
    
    return isKnown
end

-- Get global cooldown
function API.GetGlobalCooldown()
    -- Check if GCD needs update
    if GetTime() - lastGCDUpdate > 5 then
        API.UpdateGlobalCooldown()
    end
    
    return globalCooldown
end

-- Get remaining GCD
function API.GetRemainingGCD()
    -- Check cooldown of GCD
    local _, cdLeft = API.GetSpellCooldown(gcdSpellID)
    return cdLeft
end

-- Check if unit has buff
function API.UnitHasBuff(unit, spellID, sourceUnit)
    if not UnitExists(unit) then
        return false, 0, 0, 0
    end
    
    -- Use Tinkr if available for accurate buff detection
    if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
        local buff = tinkrAPI.Unit[unit]:GetBuff(spellID, sourceUnit)
        if buff then
            return true, buff.Stacks, buff.Duration, buff.ExpirationTime - GetTime()
        end
    else
        -- Fallback to WoW API
        local i = 1
        while true do
            local name, icon, count, _, duration, expirationTime, source, _, _, spellIdFound = UnitBuff(unit, i)
            if not name then
                break
            end
            
            if spellIdFound == spellID and (not sourceUnit or source == sourceUnit) then
                local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0
                return true, count, duration, remaining
            end
            
            i = i + 1
        end
    end
    
    return false, 0, 0, 0
end

-- Check if unit has debuff
function API.UnitHasDebuff(unit, spellID, sourceUnit)
    if not UnitExists(unit) then
        return false, 0, 0, 0
    end
    
    -- Use Tinkr if available for accurate debuff detection
    if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
        local debuff = tinkrAPI.Unit[unit]:GetDebuff(spellID, sourceUnit)
        if debuff then
            return true, debuff.Stacks, debuff.Duration, debuff.ExpirationTime - GetTime()
        end
    else
        -- Fallback to WoW API
        local i = 1
        while true do
            local name, icon, count, _, duration, expirationTime, source, _, _, spellIdFound = UnitDebuff(unit, i)
            if not name then
                break
            end
            
            if spellIdFound == spellID and (not sourceUnit or source == sourceUnit) then
                local remaining = expirationTime > 0 and (expirationTime - GetTime()) or 0
                return true, count, duration, remaining
            end
            
            i = i + 1
        end
    end
    
    return false, 0, 0, 0
end

-- Get unit casting information
function API.GetUnitCastInfo(unit)
    if not UnitExists(unit) then
        return nil
    end
    
    -- Try to get cast info from Tinkr
    if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
        local cast = tinkrAPI.Unit[unit]:GetCastingInfo()
        if cast then
            return {
                spellId = cast.SpellID,
                name = cast.SpellName,
                startTime = cast.CastStart,
                endTime = cast.CastEnd,
                remaining = cast.CastEnd - GetTime(),
                interruptible = not cast.Uninterruptible
            }
        end
    end
    
    -- Fallback to WoW API
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
    if name then
        return {
            spellId = spellId,
            name = name,
            startTime = startTime / 1000,
            endTime = endTime / 1000,
            remaining = (endTime / 1000) - GetTime(),
            interruptible = not notInterruptible
        }
    end
    
    -- Check channeling as well
    name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
    if name then
        return {
            spellId = spellId,
            name = name,
            startTime = startTime / 1000,
            endTime = endTime / 1000,
            remaining = (endTime / 1000) - GetTime(),
            interruptible = not notInterruptible,
            isChanneled = true
        }
    end
    
    return nil
end

-- Cast spell
function API.CastSpell(spellID, unit)
    -- Cast using Tinkr if available
    if tinkrLoaded then
        -- First try to use Tinkr's Spell object if available
        if tinkrAPI.Spell and tinkrAPI.Spell[spellID] then
            if unit then
                return tinkrAPI.Spell[spellID]:Cast(unit)
            else
                return tinkrAPI.Spell[spellID]:Cast()
            end
        -- Next try to use Tinkr's secure execution method
        elseif tinkrAPI.Secure and tinkrAPI.Secure.Call then
            if unit then
                return tinkrAPI.Secure.Call("CastSpellByID", spellID, unit)
            else
                return tinkrAPI.Secure.Call("CastSpellByID", spellID)
            end
        end
    end
    
    -- Fallback to WoW API if Tinkr not available or methods failed
    if unit then
        return CastSpellByID(spellID, unit)
    else
        return CastSpellByID(spellID)
    end
    
    return false
end

-- Cast ground-targeted spell (AoE at location)
function API.CastGroundSpell(spellID, x, y, z)
    -- If we have explicit coordinates to cast at
    if x and y and z then
        if tinkrLoaded then
            -- First try Tinkr's position casting if available
            if tinkrAPI.Spell and tinkrAPI.Spell[spellID] then
                return tinkrAPI.Spell[spellID]:CastGround(x, y, z)
            -- Next try Tinkr's secure execution if available
            elseif tinkrAPI.Secure and tinkrAPI.Secure.Call then
                -- The macro approach for ground targeting via Tinkr
                local posString = string.format("%f,%f,%f", x, y, z)
                return tinkrAPI.Secure.Call("RunMacroText", "/cast [@cursor] " .. GetSpellInfo(spellID))
            end
        end
        
        -- Fallback for WoW API is using cursor approach via macro
        return RunMacroText("/cast [@cursor] " .. GetSpellInfo(spellID))
    else
        -- Auto-determine best location
        return API.CastGroundSpellAuto(spellID)
    end
end

-- Cast ground spell at auto-determined best location
function API.CastGroundSpellAuto(spellID)
    -- Determine best AoE point based on enemy clustering
    local bestX, bestY, bestZ = API.GetBestAoEPosition(12) -- 12 yard default AoE radius
    
    -- If we found a good position
    if bestX and bestY and bestZ then
        return API.CastGroundSpell(spellID, bestX, bestY, bestZ)
    else
        -- If no good cluster found, cast at current target if valid
        if UnitExists("target") and API.IsUnitInRange("target", 40) then
            if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit["target"] then
                local tx, ty, tz = tinkrAPI.Unit["target"]:GetPosition()
                if tx and ty and tz then
                    return API.CastGroundSpell(spellID, tx, ty, tz)
                end
            end
            
            -- Fallback to cursor cast on target position
            return RunMacroText("/cast [@cursor] " .. GetSpellInfo(spellID))
        else
            -- Last resort: cast at player position
            if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit["player"] then
                local px, py, pz = tinkrAPI.Unit["player"]:GetPosition()
                if px and py and pz then
                    return API.CastGroundSpell(spellID, px, py, pz)
                end
            end
            
            -- Absolute fallback is just casting it in front of the player
            return RunMacroText("/cast [@cursor] " .. GetSpellInfo(spellID))
        end
    end
    
    return false
end

-- Cast position-targeted spell (leap/charge style)
function API.CastPositionSpell(spellID, x, y, z, minRange, maxRange)
    -- Set default ranges if not provided
    minRange = minRange or 8
    maxRange = maxRange or 25
    
    -- If we have explicit coordinates to cast at
    if x and y and z then
        -- Validate the position is in range
        if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit["player"] then
            local px, py, pz = tinkrAPI.Unit["player"]:GetPosition()
            if px and py and pz then
                local distance = math.sqrt((x-px)^2 + (y-py)^2 + (z-pz)^2)
                if distance < minRange or distance > maxRange then
                    -- Find valid position along the same vector
                    local vx, vy, vz = x-px, y-py, z-pz
                    local magnitude = math.sqrt(vx^2 + vy^2 + vz^2)
                    local nx, ny, nz = vx/magnitude, vy/magnitude, vz/magnitude
                    
                    if distance < minRange then
                        -- Position is too close, move it out to min range
                        x, y, z = px + nx * minRange, py + ny * minRange, pz + nz * minRange
                    else
                        -- Position is too far, bring it in to max range
                        x, y, z = px + nx * maxRange, py + ny * maxRange, pz + nz * maxRange
                    end
                end
            end
        end
        
        -- Cast to the position
        if tinkrLoaded then
            -- First try Tinkr's position casting if available
            if tinkrAPI.Spell and tinkrAPI.Spell[spellID] then
                return tinkrAPI.Spell[spellID]:CastGround(x, y, z)
            -- Next try Tinkr's secure execution if available
            elseif tinkrAPI.Secure and tinkrAPI.Secure.Call then
                -- The macro approach for positioning targeting via Tinkr
                return tinkrAPI.Secure.Call("RunMacroText", "/cast [@cursor] " .. GetSpellInfo(spellID))
            end
        end
        
        -- Fallback for WoW API is using cursor approach via macro
        return RunMacroText("/cast [@cursor] " .. GetSpellInfo(spellID))
    else
        -- Auto-determine best position if not provided
        return API.CastPositionSpellAuto(spellID, minRange, maxRange)
    end
end

-- Cast position spell at auto-determined best location
function API.CastPositionSpellAuto(spellID, minRange, maxRange)
    -- Set default ranges if not provided
    minRange = minRange or 8
    maxRange = maxRange or 25
    
    local targetPosition = nil
    
    -- First priority: current target if exists and in range
    if UnitExists("target") then
        local inRange = true
        local distance = API.GetUnitDistance("target")
        
        if distance < minRange or distance > maxRange then
            inRange = false
        end
        
        if inRange and tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit["target"] then
            local tx, ty, tz = tinkrAPI.Unit["target"]:GetPosition()
            if tx and ty and tz then
                targetPosition = {x = tx, y = ty, z = tz}
            end
        end
    end
    
    -- Second priority: best enemy to leap to (closest priority target)
    if not targetPosition then
        -- For classes where leaping to enemy is desirable (warrior, DH, etc)
        -- We can add class-specific logic here later
        
        -- Get all enemies in range
        local enemies = API.GetEnemiesInRange("player", maxRange)
        local closestDistance = maxRange
        local closestEnemy = nil
        
        for _, unit in ipairs(enemies) do
            local distance = API.GetUnitDistance(unit)
            if distance >= minRange and distance < closestDistance then
                closestDistance = distance
                closestEnemy = unit
            end
        end
        
        if closestEnemy and tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[closestEnemy] then
            local ex, ey, ez = tinkrAPI.Unit[closestEnemy]:GetPosition()
            if ex and ey and ez then
                targetPosition = {x = ex, y = ey, z = ez}
            end
        end
    end
    
    -- Third priority: best escape position (away from enemies)
    if not targetPosition and API.GetEnemyCount(10) > 0 then
        -- Calculate escape vector (away from nearby enemies)
        local px, py, pz = 0, 0, 0
        local enemyVectorX, enemyVectorY, enemyVectorZ = 0, 0, 0
        local enemyCount = 0
        
        if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit["player"] then
            px, py, pz = tinkrAPI.Unit["player"]:GetPosition()
        end
        
        if px ~= 0 and py ~= 0 and pz ~= 0 then
            for _, unit in ipairs(API.GetEnemiesInRange("player", 15)) do
                if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
                    local ex, ey, ez = tinkrAPI.Unit[unit]:GetPosition()
                    if ex and ey and ez then
                        enemyVectorX = enemyVectorX + (px - ex)
                        enemyVectorY = enemyVectorY + (py - ey)
                        enemyVectorZ = enemyVectorZ + (pz - ez)
                        enemyCount = enemyCount + 1
                    end
                end
            end
            
            if enemyCount > 0 then
                -- Normalize and scale to max range
                local magnitude = math.sqrt(enemyVectorX^2 + enemyVectorY^2 + enemyVectorZ^2)
                if magnitude > 0 then
                    enemyVectorX = enemyVectorX / magnitude * maxRange
                    enemyVectorY = enemyVectorY / magnitude * maxRange
                    enemyVectorZ = enemyVectorZ / magnitude * maxRange
                    
                    targetPosition = {
                        x = px + enemyVectorX,
                        y = py + enemyVectorY,
                        z = pz + enemyVectorZ
                    }
                end
            end
        end
    end
    
    -- If we found a valid position, cast to it
    if targetPosition then
        return API.CastPositionSpell(spellID, targetPosition.x, targetPosition.y, targetPosition.z, minRange, maxRange)
    end
    
    -- Fallback approach - just cast at cursor location
    return RunMacroText("/cast [@cursor] " .. GetSpellInfo(spellID))
end

-- Use item
function API.UseItem(itemID, unit)
    -- Use item using Tinkr if available
    if tinkrLoaded then
        -- First try to use Tinkr's Item object if available
        if tinkrAPI.Item and tinkrAPI.Item[itemID] then
            if unit then
                return tinkrAPI.Item[itemID]:Use(unit)
            else
                return tinkrAPI.Item[itemID]:Use()
            end
        -- Next try to use Tinkr's secure execution method
        elseif tinkrAPI.Secure and tinkrAPI.Secure.Call then
            if unit then
                return tinkrAPI.Secure.Call("UseItemByName", itemID, unit)
            else
                return tinkrAPI.Secure.Call("UseItemByName", itemID)
            end
        end
    end
    
    -- Fallback to WoW API if Tinkr not available or methods failed
    if unit then
        return UseItemByName(itemID, unit)
    else
        return UseItemByName(itemID)
    end
    
    return false
end

-- Check if item is usable
function API.IsItemUsable(itemID)
    -- Check if item exists and is usable
    local itemName = GetItemInfo(itemID)
    if not itemName then
        return false
    end
    
    -- Check cooldown
    local start, duration, enabled = GetItemCooldown(itemID)
    if start and duration and start > 0 and duration > 0 then
        return false
    end
    
    -- Check if item is usable
    local usable = IsUsableItem(itemID)
    return usable
end

-- Get unit iterator
function API.GetUnitIterator(iteratorType, ...)
    if unitIterators[iteratorType] then
        return unitIterators[iteratorType](...)
    end
    
    return function() return nil end
end

-- Get item slot
function API.GetItemSlot(itemID)
    for slot, id in pairs(playerItems) do
        if id == itemID then
            return slot
        end
    end
    
    return nil
end

-- Get item in slot
function API.GetItemInSlot(slot)
    return playerItems[slot]
end

-- Get unit auras
function API.GetUnitAuras(unit, filter)
    local auras = {}
    
    if not UnitExists(unit) then
        return auras
    end
    
    -- Use Tinkr if available
    if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
        if filter == "HELPFUL" then
            for _, buff in pairs(tinkrAPI.Unit[unit].Buffs) do
                table.insert(auras, {
                    name = buff.Name,
                    icon = buff.Icon,
                    count = buff.Stacks,
                    duration = buff.Duration,
                    expirationTime = buff.ExpirationTime,
                    source = buff.Source,
                    spellId = buff.SpellId,
                    isDebuff = false
                })
            end
        elseif filter == "HARMFUL" then
            for _, debuff in pairs(tinkrAPI.Unit[unit].Debuffs) do
                table.insert(auras, {
                    name = debuff.Name,
                    icon = debuff.Icon,
                    count = debuff.Stacks,
                    duration = debuff.Duration,
                    expirationTime = debuff.ExpirationTime,
                    source = debuff.Source,
                    spellId = debuff.SpellId,
                    isDebuff = true
                })
            end
        else
            -- Both helpful and harmful
            for _, buff in pairs(tinkrAPI.Unit[unit].Buffs) do
                table.insert(auras, {
                    name = buff.Name,
                    icon = buff.Icon,
                    count = buff.Stacks,
                    duration = buff.Duration,
                    expirationTime = buff.ExpirationTime,
                    source = buff.Source,
                    spellId = buff.SpellId,
                    isDebuff = false
                })
            end
            
            for _, debuff in pairs(tinkrAPI.Unit[unit].Debuffs) do
                table.insert(auras, {
                    name = debuff.Name,
                    icon = debuff.Icon,
                    count = debuff.Stacks,
                    duration = debuff.Duration,
                    expirationTime = debuff.ExpirationTime,
                    source = debuff.Source,
                    spellId = debuff.SpellId,
                    isDebuff = true
                })
            end
        end
    else
        -- Fallback to WoW API
        local i = 1
        while true do
            local name, icon, count, _, duration, expirationTime, source, _, _, spellId, _, _, _, _, _ = UnitAura(unit, i, filter)
            if not name then
                break
            end
            
            table.insert(auras, {
                name = name,
                icon = icon,
                count = count,
                duration = duration,
                expirationTime = expirationTime,
                source = source,
                spellId = spellId,
                isDebuff = filter == "HARMFUL"
            })
            
            i = i + 1
        end
    end
    
    return auras
end

-- Get unit cast info
function API.GetUnitCastInfo(unit)
    if not UnitExists(unit) then
        return nil
    end
    
    -- Use Tinkr if available
    if tinkrLoaded and tinkrAPI.Unit and tinkrAPI.Unit[unit] then
        local cast = tinkrAPI.Unit[unit].Cast
        if cast then
            return {
                name = cast.Name,
                text = cast.Text,
                texture = cast.Texture,
                startTime = cast.StartTime,
                endTime = cast.EndTime,
                castID = cast.ID,
                spellId = cast.SpellId,
                notInterruptible = not cast.Interruptible
            }
        end
    else
        -- Fallback to WoW API
        local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
        if name then
            return {
                name = name,
                text = text,
                texture = texture,
                startTime = startTime / 1000,
                endTime = endTime / 1000,
                castID = castID,
                spellId = spellId,
                notInterruptible = notInterruptible
            }
        end
        
        -- Check for channeled spell
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
        if name then
            return {
                name = name,
                text = text,
                texture = texture,
                startTime = startTime / 1000,
                endTime = endTime / 1000,
                castID = 0,
                spellId = spellId,
                notInterruptible = notInterruptible,
                isChanneled = true
            }
        end
    end
    
    return nil
end

-- Register for Tinkr API
if Tinkr and Tinkr.Util then
    Tinkr.Util.RegisterForAPI(addonName, function() 
        API.InitializeTinkrAPI()
    end)
end

-- Register for export
WR.API = API

return API