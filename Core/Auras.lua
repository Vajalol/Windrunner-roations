local addonName, WR = ...

-- Auras module - handles buff/debuff tracking and monitoring
local Auras = {}
WR.Auras = Auras

-- State
local state = {
    unitAuras = {}, -- {unit = {auraId = {name, duration, expirationTime, stacks, type, etc.}}}
    auraCache = {}, -- {unit = {lastUpdate, buffs = {}, debuffs = {}}}
    importantAuras = {}, -- {auraId = {priority, isBuff, isDebuff}}
    auraGroups = {}, -- Groups of related auras for easier tracking, e.g. all DoTs
    lastUpdate = 0,
    updateInterval = 0.1, -- Update auras every 100ms
    cacheDuration = 0.2, -- Cache results for 200ms
}

-- Initialize the auras module
function Auras:Initialize()
    -- Create a frame for OnUpdate and events
    local frame = CreateFrame("Frame")
    
    -- Set up OnUpdate handler
    frame:SetScript("OnUpdate", function(self, elapsed)
        Auras:OnUpdate(elapsed)
    end)
    
    -- Register for events
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_AURA" then
            Auras:UNIT_AURA(...)
        elseif event == "PLAYER_TARGET_CHANGED" then
            Auras:ClearCache("target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            Auras:ClearCache("focus")
        elseif event == "PLAYER_ENTERING_WORLD" then
            Auras:ClearAllCaches()
        end
    end)
    
    -- Register important auras to track for efficiency
    self:RegisterImportantAuras()
    
    -- Register aura groups
    self:RegisterAuraGroups()
    
    WR:Debug("Auras module initialized")
end

-- OnUpdate handler
function Auras:OnUpdate(elapsed)
    local now = GetTime()
    
    -- Don't update too frequently
    if now - state.lastUpdate < state.updateInterval then return end
    state.lastUpdate = now
    
    -- Check cache expirations
    for unit, cacheData in pairs(state.auraCache) do
        if now - cacheData.lastUpdate > state.cacheDuration then
            -- Cache expired, clear it
            state.auraCache[unit] = nil
        end
    end
    
    -- Update player buffs (always monitored)
    self:UpdateUnitAuras("player", "HELPFUL")
    
    -- Update target debuffs (always monitored) if target exists
    if UnitExists("target") then
        self:UpdateUnitAuras("target", "HARMFUL")
    end
end

-- Handle UNIT_AURA event
function Auras:UNIT_AURA(unit)
    -- Clear any cache for this unit
    self:ClearCache(unit)
    
    -- Immediately update auras for this unit
    self:UpdateUnitAuras(unit, "HELPFUL")
    self:UpdateUnitAuras(unit, "HARMFUL")
end

-- Update auras for a specific unit
function Auras:UpdateUnitAuras(unit, filter)
    if not unit or not UnitExists(unit) then return end
    
    -- Initialize unit table if needed
    if not state.unitAuras[unit] then
        state.unitAuras[unit] = {}
    end
    
    local auraCount = 0
    local index = 1
    
    while true do
        local name, icon, count, auraType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer,
              nameplateShowAll, timeMod = UnitAura(unit, index, filter)
        
        if not name then break end
        
        -- If this is in our important auras list, or coming from the player, track it
        if state.importantAuras[spellId] or (source and UnitIsUnit(source, "player")) then
            state.unitAuras[unit][spellId] = {
                name = name,
                icon = icon,
                count = count or 0,
                auraType = auraType,
                duration = duration or 0,
                expirationTime = expirationTime or 0,
                source = source,
                isStealable = isStealable,
                nameplateShowPersonal = nameplateShowPersonal,
                spellId = spellId,
                canApplyAura = canApplyAura,
                isBossDebuff = isBossDebuff,
                castByPlayer = castByPlayer or (source and UnitIsUnit(source, "player")),
                nameplateShowAll = nameplateShowAll,
                timeMod = timeMod,
                filter = filter
            }
            
            auraCount = auraCount + 1
        end
        
        index = index + 1
    end
    
    -- Update the cache
    if not state.auraCache[unit] then
        state.auraCache[unit] = {
            lastUpdate = GetTime(),
            buffs = {},
            debuffs = {}
        }
    else
        state.auraCache[unit].lastUpdate = GetTime()
    end
    
    -- Store aura data in the appropriate cache
    if filter == "HELPFUL" then
        state.auraCache[unit].buffs = {}
        for spellId, auraData in pairs(state.unitAuras[unit]) do
            if auraData.filter == "HELPFUL" then
                state.auraCache[unit].buffs[spellId] = auraData
            end
        end
    elseif filter == "HARMFUL" then
        state.auraCache[unit].debuffs = {}
        for spellId, auraData in pairs(state.unitAuras[unit]) do
            if auraData.filter == "HARMFUL" then
                state.auraCache[unit].debuffs[spellId] = auraData
            end
        end
    end
    
    WR:Debug("Updated", filter, "auras for", unit, "-", auraCount, "auras found")
end

-- Register important auras to track
function Auras:RegisterImportantAuras()
    -- Class-specific important auras
    local playerClass, _ = UnitClass("player")
    
    if playerClass == "MAGE" then
        -- Mage buffs
        self:RegisterImportantAura(1459, 10, true, false) -- Arcane Intellect
        self:RegisterImportantAura(12051, 60, true, false) -- Evocation
        self:RegisterImportantAura(12472, 90, true, false) -- Icy Veins
        self:RegisterImportantAura(190319, 80, true, false) -- Combustion
        self:RegisterImportantAura(12042, 80, true, false) -- Arcane Power
        
        -- Mage debuffs
        self:RegisterImportantAura(212792, 70, false, true) -- Cone of Cold
        self:RegisterImportantAura(122, 50, false, true) -- Frost Nova
        self:RegisterImportantAura(118, 60, false, true) -- Polymorph
        
    elseif playerClass == "WARRIOR" then
        -- Warrior buffs
        self:RegisterImportantAura(1719, 90, true, false) -- Recklessness
        self:RegisterImportantAura(12292, 80, true, false) -- Bloodbath
        self:RegisterImportantAura(871, 70, true, false) -- Shield Wall
        
        -- Warrior debuffs
        self:RegisterImportantAura(1160, 60, false, true) -- Demoralizing Shout
        self:RegisterImportantAura(355, 50, false, true) -- Taunt
        
    elseif playerClass == "DRUID" then
        -- Druid buffs
        self:RegisterImportantAura(774, 70, true, false) -- Rejuvenation
        self:RegisterImportantAura(8936, 75, true, false) -- Regrowth
        self:RegisterImportantAura(33763, 80, true, false) -- Lifebloom
        self:RegisterImportantAura(48438, 60, true, false) -- Wild Growth
        
        -- Druid debuffs
        self:RegisterImportantAura(164812, 70, false, true) -- Moonfire
        self:RegisterImportantAura(164815, 70, false, true) -- Sunfire
        self:RegisterImportantAura(1079, 75, false, true) -- Rip
        
    elseif playerClass == "PRIEST" then
        -- Priest buffs
        self:RegisterImportantAura(17, 75, true, false) -- Power Word: Shield
        self:RegisterImportantAura(139, 70, true, false) -- Renew
        self:RegisterImportantAura(33206, 90, true, false) -- Pain Suppression
        
        -- Priest debuffs
        self:RegisterImportantAura(589, 70, false, true) -- Shadow Word: Pain
        self:RegisterImportantAura(34914, 80, false, true) -- Vampiric Touch
        
    elseif playerClass == "HUNTER" then
        -- Hunter buffs
        self:RegisterImportantAura(3045, 80, true, false) -- Rapid Fire
        self:RegisterImportantAura(19574, 85, true, false) -- Bestial Wrath
        
        -- Hunter debuffs
        self:RegisterImportantAura(3355, 60, false, true) -- Freezing Trap
        self:RegisterImportantAura(1978, 70, false, true) -- Serpent Sting
    end
    
    -- General important auras (for all classes)
    
    -- General buffs
    self:RegisterImportantAura(2825, 95, true, false) -- Bloodlust
    self:RegisterImportantAura(32182, 95, true, false) -- Heroism
    self:RegisterImportantAura(80353, 95, true, false) -- Time Warp
    self:RegisterImportantAura(90355, 95, true, false) -- Ancient Hysteria
    
    -- General debuffs
    self:RegisterImportantAura(57724, 90, false, true) -- Sated (Bloodlust debuff)
    self:RegisterImportantAura(80354, 90, false, true) -- Temporal Displacement (Time Warp debuff)
    
    WR:Debug("Registered important auras for class:", playerClass)
end

-- Register a single important aura
function Auras:RegisterImportantAura(auraId, priority, isBuff, isDebuff)
    state.importantAuras[auraId] = {
        priority = priority or 50, -- Default medium priority
        isBuff = isBuff or false,
        isDebuff = isDebuff or false
    }
end

-- Register aura groups for easier tracking
function Auras:RegisterAuraGroups()
    -- Group for DoTs (damage over time effects)
    state.auraGroups.dots = {
        name = "Damage Over Time",
        auras = {
            -- Warlock
            [980] = true, -- Agony
            [146739] = true, -- Corruption
            [316099] = true, -- Unstable Affliction
            -- Priest
            [589] = true, -- Shadow Word: Pain
            [34914] = true, -- Vampiric Touch
            -- Druid
            [164812] = true, -- Moonfire
            [164815] = true, -- Sunfire
            [1079] = true, -- Rip
            -- Hunter
            [1978] = true, -- Serpent Sting
            -- Rogue
            [703] = true, -- Garrote
            [1943] = true, -- Rupture
            -- Death Knight
            [55095] = true, -- Frost Fever
            [55078] = true, -- Blood Plague
            -- Mage
            [12654] = true, -- Ignite
            [205021] = true, -- Frostbite
        }
    }
    
    -- Group for HoTs (healing over time effects)
    state.auraGroups.hots = {
        name = "Healing Over Time",
        auras = {
            -- Druid
            [774] = true, -- Rejuvenation
            [8936] = true, -- Regrowth
            [33763] = true, -- Lifebloom
            -- Priest
            [139] = true, -- Renew
            -- Shaman
            [61295] = true, -- Riptide
            -- Monk
            [119611] = true, -- Renewing Mist
            [124682] = true, -- Enveloping Mist
        }
    }
    
    -- Group for CC effects (crowd control)
    state.auraGroups.cc = {
        name = "Crowd Control",
        auras = {
            -- Mage
            [118] = true, -- Polymorph
            -- Druid
            [339] = true, -- Entangling Roots
            -- Hunter
            [3355] = true, -- Freezing Trap
            -- Priest
            [605] = true, -- Mind Control
            -- Rogue
            [6770] = true, -- Sap
            -- Warlock
            [5782] = true, -- Fear
            -- Warrior
            [5246] = true, -- Intimidating Shout
            -- Paladin
            [20066] = true, -- Repentance
            -- Monk
            [115078] = true, -- Paralysis
            -- Demon Hunter
            [207685] = true, -- Sigil of Misery
            -- Death Knight
            [91807] = true, -- Shambling Rush (Ghoul stun)
            -- Shaman
            [51514] = true, -- Hex
        }
    }
    
    -- Group for defensive cooldowns
    state.auraGroups.defensives = {
        name = "Defensive Cooldowns",
        auras = {
            -- Warrior
            [871] = true, -- Shield Wall
            [12975] = true, -- Last Stand
            -- Paladin
            [86659] = true, -- Guardian of Ancient Kings
            [31850] = true, -- Ardent Defender
            -- Death Knight
            [48707] = true, -- Anti-Magic Shell
            [55233] = true, -- Vampiric Blood
            -- Druid
            [22812] = true, -- Barkskin
            [61336] = true, -- Survival Instincts
            -- Monk
            [115203] = true, -- Fortifying Brew
            [122278] = true, -- Dampen Harm
            -- Demon Hunter
            [187827] = true, -- Metamorphosis
            [196555] = true, -- Netherwalk
            -- Mage
            [45438] = true, -- Ice Block
            [113862] = true, -- Greater Invisibility
            -- Priest
            [47585] = true, -- Dispersion
            [33206] = true, -- Pain Suppression
            -- Rogue
            [5277] = true, -- Evasion
            [31224] = true, -- Cloak of Shadows
            -- Hunter
            [186265] = true, -- Aspect of the Turtle
            -- Warlock
            [104773] = true, -- Unending Resolve
            -- Shaman
            [108271] = true, -- Astral Shift
        }
    }
    
    -- Group for offensive cooldowns
    state.auraGroups.offensives = {
        name = "Offensive Cooldowns",
        auras = {
            -- Warrior
            [1719] = true, -- Recklessness
            -- Paladin
            [31884] = true, -- Avenging Wrath
            -- Death Knight
            [47568] = true, -- Empower Rune Weapon
            -- Druid
            [194223] = true, -- Celestial Alignment
            [102560] = true, -- Incarnation: Chosen of Elune
            -- Monk
            [137639] = true, -- Storm, Earth, and Fire
            [152173] = true, -- Serenity
            -- Demon Hunter
            [191427] = true, -- Metamorphosis
            -- Mage
            [12472] = true, -- Icy Veins
            [190319] = true, -- Combustion
            [12042] = true, -- Arcane Power
            -- Priest
            [10060] = true, -- Power Infusion
            [194249] = true, -- Voidform
            -- Rogue
            [13750] = true, -- Adrenaline Rush
            [121471] = true, -- Shadow Blades
            -- Hunter
            [19574] = true, -- Bestial Wrath
            [266779] = true, -- Coordinated Assault
            -- Warlock
            [113858] = true, -- Dark Soul: Instability
            -- Shaman
            [114051] = true, -- Ascendance
        }
    }
    
    WR:Debug("Registered", #state.auraGroups, "aura groups")
end

-- Clear the cache for a specific unit
function Auras:ClearCache(unit)
    if not unit then return end
    
    state.auraCache[unit] = nil
end

-- Clear all caches
function Auras:ClearAllCaches()
    wipe(state.auraCache)
end

-- Check if a unit has a specific aura
function Auras:UnitHasAura(unit, auraID, filter)
    if not unit or not UnitExists(unit) then return false end
    
    -- Try to use our cache first
    if state.auraCache[unit] and GetTime() - state.auraCache[unit].lastUpdate <= state.cacheDuration then
        if filter == "HELPFUL" and state.auraCache[unit].buffs[auraID] then
            return true
        elseif filter == "HARMFUL" and state.auraCache[unit].debuffs[auraID] then
            return true
        end
    end
    
    -- Direct check - can be by spell ID or name
    local isNumber = type(auraID) == "number"
    local i = 1
    
    while true do
        local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
        if not name then break end
        
        if (isNumber and spellId == auraID) or (not isNumber and name == auraID) then
            return true
        end
        
        i = i + 1
    end
    
    return false
end

-- Get aura info for a specific aura on a unit
function Auras:GetAuraInfo(unit, auraID, filter)
    if not unit or not UnitExists(unit) then return nil end
    
    -- Try to use our cache first
    if state.auraCache[unit] and GetTime() - state.auraCache[unit].lastUpdate <= state.cacheDuration then
        if filter == "HELPFUL" and state.auraCache[unit].buffs[auraID] then
            return state.auraCache[unit].buffs[auraID]
        elseif filter == "HARMFUL" and state.auraCache[unit].debuffs[auraID] then
            return state.auraCache[unit].debuffs[auraID]
        end
    end
    
    -- Direct check - can be by spell ID or name
    local isNumber = type(auraID) == "number"
    local i = 1
    
    while true do
        local name, icon, count, auraType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer,
              nameplateShowAll, timeMod = UnitAura(unit, i, filter)
        
        if not name then break end
        
        if (isNumber and spellId == auraID) or (not isNumber and name == auraID) then
            return {
                name = name,
                icon = icon,
                count = count or 0,
                auraType = auraType,
                duration = duration or 0,
                expirationTime = expirationTime or 0,
                source = source,
                isStealable = isStealable,
                nameplateShowPersonal = nameplateShowPersonal,
                spellId = spellId,
                canApplyAura = canApplyAura,
                isBossDebuff = isBossDebuff,
                castByPlayer = castByPlayer or (source and UnitIsUnit(source, "player")),
                nameplateShowAll = nameplateShowAll,
                timeMod = timeMod,
                filter = filter
            }
        end
        
        i = i + 1
    end
    
    return nil
end

-- Get the remaining time for an aura
function Auras:GetAuraRemaining(unit, auraID, filter)
    local auraInfo = self:GetAuraInfo(unit, auraID, filter)
    
    if auraInfo then
        local remaining = auraInfo.expirationTime - GetTime()
        if remaining < 0 then remaining = 0 end
        return remaining
    end
    
    return 0
end

-- Get the duration for an aura
function Auras:GetAuraDuration(unit, auraID, filter)
    local auraInfo = self:GetAuraInfo(unit, auraID, filter)
    
    if auraInfo then
        return auraInfo.duration
    end
    
    return 0
end

-- Get the stacks for an aura
function Auras:GetAuraStacks(unit, auraID, filter)
    local auraInfo = self:GetAuraInfo(unit, auraID, filter)
    
    if auraInfo then
        return auraInfo.count
    end
    
    return 0
end

-- Check if the player has any aura from a specific group
function Auras:PlayerHasAuraFromGroup(groupName)
    if not state.auraGroups[groupName] then return false end
    
    local group = state.auraGroups[groupName]
    
    -- Try buffs first
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not spellId then break end
        
        if group.auras[spellId] then
            return true
        end
    end
    
    -- Then try debuffs (some groups like CC can be both)
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("player", i)
        if not spellId then break end
        
        if group.auras[spellId] then
            return true
        end
    end
    
    return false
end

-- Check if the target has any aura from a specific group
function Auras:TargetHasAuraFromGroup(groupName)
    if not state.auraGroups[groupName] or not UnitExists("target") then return false end
    
    local group = state.auraGroups[groupName]
    
    -- Try buffs first
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitBuff("target", i)
        if not spellId then break end
        
        if group.auras[spellId] then
            return true
        end
    end
    
    -- Then try debuffs
    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId = UnitDebuff("target", i)
        if not spellId then break end
        
        if group.auras[spellId] then
            return true
        end
    end
    
    return false
end

-- Get all player buffs that match a filter function
function Auras:GetPlayerBuffs(filterFunc)
    local result = {}
    
    for i = 1, 40 do
        local name, icon, count, auraType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = UnitBuff("player", i)
        
        if not name then break end
        
        local auraInfo = {
            name = name,
            icon = icon,
            count = count or 0,
            auraType = auraType,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
            source = source,
            isStealable = isStealable,
            nameplateShowPersonal = nameplateShowPersonal,
            spellId = spellId,
            filter = "HELPFUL"
        }
        
        if not filterFunc or filterFunc(auraInfo) then
            table.insert(result, auraInfo)
        end
    end
    
    return result
end

-- Get all target debuffs that match a filter function
function Auras:GetTargetDebuffs(filterFunc)
    if not UnitExists("target") then return {} end
    
    local result = {}
    
    for i = 1, 40 do
        local name, icon, count, auraType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = UnitDebuff("target", i)
        
        if not name then break end
        
        local auraInfo = {
            name = name,
            icon = icon,
            count = count or 0,
            auraType = auraType,
            duration = duration or 0,
            expirationTime = expirationTime or 0,
            source = source,
            isStealable = isStealable,
            nameplateShowPersonal = nameplateShowPersonal,
            spellId = spellId,
            filter = "HARMFUL"
        }
        
        if not filterFunc or filterFunc(auraInfo) then
            table.insert(result, auraInfo)
        end
    end
    
    return result
end

-- Initialize the module
Auras:Initialize()

return Auras