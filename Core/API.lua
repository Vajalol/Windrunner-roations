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
    
    -- Register addon events
    API.RegisterEvent("ADDON_LOADED", API.OnAddonLoaded)
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
    if Tinkr then
        tinkrLoaded = true
        tinkrAPI = Tinkr
        API.PrintDebug("Tinkr API detected and loaded")
    else
        tinkrLoaded = false
        table.insert(loadErrors, "Tinkr not detected. Make sure Tinkr is installed and loaded.")
        API.PrintError("Tinkr not detected. Make sure Tinkr is installed and loaded.")
    end
end

-- Clear caches
function API.ClearCaches()
    API.ClearUnitCache()
    API.ClearSpellCache()
    API.ClearCooldownCache()
    API.ClearItemCache()
}

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
    API.PrintMessage("Debug mode " .. (enable and "enabled" : "disabled"))
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

-- Cast spell
function API.CastSpell(spellID, unit)
    -- Cast using Tinkr if available
    if tinkrLoaded and tinkrAPI.Spell then
        if tinkrAPI.Spell[spellID] then
            if unit then
                return tinkrAPI.Spell[spellID]:Cast(unit)
            else
                return tinkrAPI.Spell[spellID]:Cast()
            end
        end
    else
        -- Fallback to WoW API
        if unit then
            return CastSpellByID(spellID, unit)
        else
            return CastSpellByID(spellID)
        end
    end
    
    return false
end

-- Use item
function API.UseItem(itemID, unit)
    -- Use item using Tinkr if available
    if tinkrLoaded and tinkrAPI.Item then
        if tinkrAPI.Item[itemID] then
            if unit then
                return tinkrAPI.Item[itemID]:Use(unit)
            else
                return tinkrAPI.Item[itemID]:Use()
            end
        end
    else
        -- Fallback to WoW API
        if unit then
            return UseItemByName(itemID, unit)
        else
            return UseItemByName(itemID)
        end
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