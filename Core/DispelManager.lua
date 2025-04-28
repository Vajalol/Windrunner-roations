-- DispelManager.lua
-- Handles automatic dispelling of harmful effects
local addonName, WR = ...
local DispelManager = {}
WR.DispelManager = DispelManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local enableAutoDispel = true
local lastDispelTime = 0
local MIN_DISPEL_INTERVAL = 1.0  -- Minimum seconds between dispels
local dispelableDebuffs = {}  -- Cache of dispelable debuffs on party members
local debuffCache = {}  -- Cache of all debuffs, for determining importance
local dispelCooldowns = {}  -- Tracks cooldowns of dispel abilities
local partyMembers = {}  -- Party/raid members for dispel scanning

-- Important debuff types to prioritize
local importantDebuffTypes = {
    ["Magic"] = true,
    ["Curse"] = true,
    ["Disease"] = true,
    ["Poison"] = true
}

-- Class-specific dispel abilities
local dispelAbilities = {
    ["PRIEST"] = {
        {id = 527, name = "Purify", types = {"Magic", "Disease"}, target = "friendly", cooldown = 8, specId = {1, 2}},  -- Discipline and Holy
        {id = 213634, name = "Purify Disease", types = {"Disease"}, target = "friendly", cooldown = 8, specId = {3}}  -- Shadow
    },
    ["PALADIN"] = {
        {id = 4987, name = "Cleanse", types = {"Magic", "Poison", "Disease"}, target = "friendly", cooldown = 8, specId = {1}},  -- Holy
        {id = 213644, name = "Cleanse Toxins", types = {"Poison", "Disease"}, target = "friendly", cooldown = 8, specId = {2, 3}}  -- Ret and Prot
    },
    ["DRUID"] = {
        {id = 2782, name = "Remove Corruption", types = {"Curse", "Poison"}, target = "friendly", cooldown = 8, specId = {1, 2, 3}},  -- Balance, Feral, Guardian
        {id = 88423, name = "Nature's Cure", types = {"Magic", "Curse", "Poison"}, target = "friendly", cooldown = 8, specId = {4}}  -- Restoration
    },
    ["SHAMAN"] = {
        {id = 51886, name = "Cleanse Spirit", types = {"Curse"}, target = "friendly", cooldown = 8, specId = {1, 2}},  -- Elemental, Enhancement
        {id = 77130, name = "Purify Spirit", types = {"Magic", "Curse"}, target = "friendly", cooldown = 8, specId = {3}}  -- Restoration
    },
    ["MONK"] = {
        {id = 115450, name = "Detox", types = {"Magic", "Poison", "Disease"}, target = "friendly", cooldown = 8, specId = {2}},  -- Mistweaver
        {id = 218164, name = "Detox", types = {"Poison", "Disease"}, target = "friendly", cooldown = 8, specId = {1, 3}}  -- Brewmaster, Windwalker
    },
    ["MAGE"] = {
        {id = 475, name = "Remove Curse", types = {"Curse"}, target = "friendly", cooldown = 8}
    },
    ["WARLOCK"] = {
        {id = 89808, name = "Singe Magic", types = {"Magic"}, target = "friendly", cooldown = 15, petSpell = true}  -- Imp spell
    },
    ["EVOKER"] = {
        {id = 365585, name = "Expunge", types = {"Poison", "Disease", "Curse"}, target = "friendly", cooldown = 8}
    }
}

-- Dispel priority for debuff types (lower = higher priority)
local debuffTypePriority = {
    ["Magic"] = 10,
    ["Curse"] = 20,
    ["Disease"] = 30,
    ["Poison"] = 40
}

-- High priority debuffs to dispel immediately
local highPriorityDebuffs = {
    -- Raid-killing mechanics
    375901, -- Choking Rotcloud
    388392, -- Stagnant Winds
    377864, -- Infectious Corruption
    
    -- CC effects
    118, -- Polymorph
    28272, -- Polymorph (Pig)
    28271, -- Polymorph (Turtle)
    61305, -- Polymorph (Black Cat)
    61721, -- Polymorph (Rabbit)
    61780, -- Polymorph (Turkey)
    5782, -- Fear
    8122, -- Psychic Scream
    5484, -- Howl of Terror
    6358, -- Seduction
    6789, -- Mortal Coil
    9484, -- Shackle Undead
    20066, -- Repentance
    2094, -- Blind
    
    -- Major debuffs in PvP
    316099, -- Unstable Affliction
    34914, -- Vampiric Touch
    3409,  -- Crippling Poison
    212183 -- Smoke Bomb
}

-- Debuffs to ignore (don't dispel) - either can't be dispelled or beneficial
local ignoreDebuffs = {
    -- Can't be removed
    316099, -- Unstable Affliction
    34914, -- Vampiric Touch
    
    -- Beneficial debuffs
    363916, -- Mana Regeneration
    363917, -- Health Regeneration
    326450, -- Loyalty Badge
    
    -- Periodic damage effects that dispelling would cause more harm than good
    146739, -- Corruption
    980,    -- Agony
    
    -- Special Mechanic debuffs (removal would break encounter mechanics)
    327255, -- Anima Infusion
    339525, -- Anima Link
    
    -- Mind control/possession debuffs
    605    -- Mind Control
}

-- Initialize module
function DispelManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events for debuff tracking
    API.RegisterEvent("UNIT_AURA", function(unit)
        self:UpdateUnitDebuffs(unit)
    end)
    
    -- Register for party updates
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:UpdatePartyMembers()
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:UpdatePartyMembers()
    end)
    
    -- Initial update of party members
    self:UpdatePartyMembers()
    
    API.PrintDebug("Dispel Manager initialized")
    return true
end

-- Register settings
function DispelManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("DispelManager", {
        dispelSettings = {
            enableAutoDispel = {
                displayName = "Auto-Dispel",
                description = "Automatically dispel harmful effects",
                type = "toggle",
                default = true
            },
            prioritizeTanks = {
                displayName = "Prioritize Tanks",
                description = "Prioritize dispelling tanks over other roles",
                type = "toggle",
                default = true
            },
            prioritizeHealer = {
                displayName = "Prioritize Healers",
                description = "Prioritize dispelling healers over DPS",
                type = "toggle",
                default = true
            },
            dispelInCombatOnly = {
                displayName = "In Combat Only",
                description = "Only dispel in combat",
                type = "toggle",
                default = false
            },
            dispelMagic = {
                displayName = "Dispel Magic",
                description = "Dispel Magic debuff types",
                type = "toggle",
                default = true
            },
            dispelCurse = {
                displayName = "Dispel Curse",
                description = "Dispel Curse debuff types",
                type = "toggle",
                default = true
            },
            dispelDisease = {
                displayName = "Dispel Disease",
                description = "Dispel Disease debuff types",
                type = "toggle",
                default = true
            },
            dispelPoison = {
                displayName = "Dispel Poison",
                description = "Dispel Poison debuff types",
                type = "toggle",
                default = true
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("DispelManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function DispelManager:ApplySettings(settings)
    -- Apply dispel settings
    enableAutoDispel = settings.dispelSettings.enableAutoDispel
    prioritizeTanks = settings.dispelSettings.prioritizeTanks
    prioritizeHealer = settings.dispelSettings.prioritizeHealer
    dispelInCombatOnly = settings.dispelSettings.dispelInCombatOnly
    dispelMagic = settings.dispelSettings.dispelMagic
    dispelCurse = settings.dispelSettings.dispelCurse
    dispelDisease = settings.dispelSettings.dispelDisease
    dispelPoison = settings.dispelSettings.dispelPoison
    
    API.PrintDebug("Dispel Manager settings applied")
end

-- Update settings from external source
function DispelManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enableAutoDispel ~= nil then
        enableAutoDispel = newSettings.enableAutoDispel
    end
end

-- Update party member list
function DispelManager:UpdatePartyMembers()
    -- Clear current party members
    partyMembers = {}
    
    -- Add player
    table.insert(partyMembers, {
        unit = "player",
        name = UnitName("player"),
        class = select(2, UnitClass("player")),
        role = self:GetUnitRole("player"),
        priority = self:CalculateUnitPriority("player")
    })
    
    -- Check if in a group
    if IsInGroup() then
        local numMembers = GetNumGroupMembers()
        local prefix = IsInRaid() and "raid" or "party"
        
        for i = 1, numMembers do
            local unit = prefix .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                table.insert(partyMembers, {
                    unit = unit,
                    name = UnitName(unit),
                    class = select(2, UnitClass(unit)),
                    role = self:GetUnitRole(unit),
                    priority = self:CalculateUnitPriority(unit)
                })
            end
        end
    end
    
    -- Reset debuff tracking
    dispelableDebuffs = {}
    debuffCache = {}
    
    API.PrintDebug("Updated party members: " .. #partyMembers)
end

-- Get unit's assigned role
function DispelManager:GetUnitRole(unit)
    if not unit then return "NONE" end
    
    local role = UnitGroupRolesAssigned(unit)
    if role and role ~= "NONE" then
        return role
    end
    
    -- Fallback logic if role isn't assigned
    local className = select(2, UnitClass(unit))
    if not className then return "NONE" end
    
    -- Very simplified role assignment, would be improved in a real implementation
    if className == "WARRIOR" or className == "DEATHKNIGHT" or className == "PALADIN" or className == "DRUID" then
        return "TANK"  -- Could be a tank
    elseif className == "PRIEST" or className == "PALADIN" or className == "DRUID" or className == "MONK" or className == "SHAMAN" then
        return "HEALER"  -- Could be a healer
    else
        return "DAMAGER"  -- Assume DPS
    end
end

-- Calculate a priority value for a unit (lower = higher priority)
function DispelManager:CalculateUnitPriority(unit)
    if not unit then return 100 end
    
    local role = self:GetUnitRole(unit)
    local baseValue = 50
    
    -- Priority adjustments based on role
    if role == "TANK" then
        baseValue = baseValue - 20  -- Higher priority for tanks
    elseif role == "HEALER" then
        baseValue = baseValue - 10  -- Medium priority for healers
    end
    
    -- Adjust for player (slightly prioritize self-dispels)
    if UnitIsUnit(unit, "player") then
        baseValue = baseValue - 5
    end
    
    return baseValue
end

-- Update the debuffs on a specific unit
function DispelManager:UpdateUnitDebuffs(unit)
    if not unit or not UnitExists(unit) then return end
    
    -- Find the party member data
    local memberData = nil
    for _, member in ipairs(partyMembers) do
        if UnitIsUnit(member.unit, unit) then
            memberData = member
            break
        end
    end
    
    if not memberData then return end  -- Unit not in our party list
    
    -- Get dispellable debuffs on this unit
    local dispellable = self:GetDispellableDebuffsOnUnit(unit)
    
    -- Update our cache
    dispelableDebuffs[unit] = dispellable
end

-- Get all dispellable debuffs on a unit
function DispelManager:GetDispellableDebuffsOnUnit(unit)
    if not unit then return {} end
    
    -- Get player class and capabilities
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    local canDispelTypes = self:GetDispellableTypes(playerClass, playerSpec)
    
    -- If we can't dispel anything, return empty
    if not canDispelTypes or #canDispelTypes == 0 then
        return {}
    end
    
    -- Build a table of dispel type capabilities
    local canDispel = {}
    for _, dispelType in ipairs(canDispelTypes) do
        canDispel[dispelType] = true
    end
    
    -- Get dispellable debuffs on this unit
    local dispellable = {}
    
    -- Only check friendly units
    if not UnitIsFriend("player", unit) then
        return {}
    end
    
    -- Scan all debuffs on the unit
    local i = 1
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellId = UnitDebuff(unit, i)
        
        if not name then break end  -- No more debuffs
        
        -- Store this debuff in our general cache
        if not debuffCache[spellId] then
            debuffCache[spellId] = {
                name = name,
                icon = icon,
                debuffType = debuffType,
                count = 0
            }
        end
        
        -- Increment count of this debuff type
        debuffCache[spellId].count = debuffCache[spellId].count + 1
        
        -- Check if this is dispellable by us
        if debuffType and canDispel[debuffType] and not self:IsIgnoredDebuff(spellId) then
            local priority = self:CalculateDebuffPriority(spellId, debuffType)
            
            table.insert(dispellable, {
                name = name,
                icon = icon,
                count = count,
                debuffType = debuffType,
                duration = duration,
                expirationTime = expirationTime,
                spellId = spellId,
                priority = priority
            })
        end
        
        i = i + 1
    end
    
    -- Sort by priority (lower number = higher priority)
    table.sort(dispellable, function(a, b) return a.priority < b.priority end)
    
    return dispellable
end

-- Calculate a priority value for a debuff (lower = higher priority)
function DispelManager:CalculateDebuffPriority(spellId, debuffType)
    local basePriority = 50
    
    -- High priority debuffs get top priority
    for _, highPrioId in ipairs(highPriorityDebuffs) do
        if spellId == highPrioId then
            return 1  -- Maximum priority
        end
    end
    
    -- Adjust priority based on debuff type
    if debuffType and debuffTypePriority[debuffType] then
        basePriority = basePriority + debuffTypePriority[debuffType]
    end
    
    -- More logic could be added here for specific encounter mechanics
    
    return basePriority
end

-- Check if a debuff should be ignored (not dispelled)
function DispelManager:IsIgnoredDebuff(spellId)
    for _, ignoreId in ipairs(ignoreDebuffs) do
        if spellId == ignoreId then
            return true
        end
    end
    
    return false
end

-- Get the types of debuffs the player can dispel
function DispelManager:GetDispellableTypes(playerClass, playerSpec)
    -- Get the dispel abilities for this class
    local abilities = dispelAbilities[playerClass]
    if not abilities then return {} end
    
    -- Check each ability to see if it's usable
    local dispellableTypes = {}
    local typesMap = {}  -- For deduplication
    
    for _, ability in ipairs(abilities) do
        -- Skip spec-restricted abilities for the wrong spec
        if ability.specId and not self:IsMatchingSpec(playerSpec, ability.specId) then
            -- Skip this ability
        elseif ability.petSpell then
            -- Check if we have the pet with this spell active
            -- For simplicity, we'll just assume it's available if the player is a Warlock
            if playerClass == "WARLOCK" then
                for _, dispelType in ipairs(ability.types) do
                    if not typesMap[dispelType] then
                        typesMap[dispelType] = true
                        table.insert(dispellableTypes, dispelType)
                    end
                end
            end
        else
            -- Regular ability, check if known
            if API.IsSpellKnown(ability.id) then
                for _, dispelType in ipairs(ability.types) do
                    if not typesMap[dispelType] then
                        typesMap[dispelType] = true
                        table.insert(dispellableTypes, dispelType)
                    end
                end
            end
        end
    end
    
    return dispellableTypes
end

-- Check if the player's spec matches a list of specs
function DispelManager:IsMatchingSpec(playerSpec, specList)
    if not playerSpec or not specList then return false end
    
    for _, specId in ipairs(specList) do
        if playerSpec == specId then
            return true
        end
    end
    
    return false
end

-- Get the best dispel ability for a given debuff type
function DispelManager:GetDispelAbilityForType(debuffType)
    local playerClass = select(2, UnitClass("player"))
    local playerSpec = GetSpecialization()
    
    -- Get abilities for this class
    local abilities = dispelAbilities[playerClass]
    if not abilities then return nil end
    
    -- Find a matching ability
    for _, ability in ipairs(abilities) do
        -- Skip spec-restricted abilities for the wrong spec
        if ability.specId and not self:IsMatchingSpec(playerSpec, ability.specId) then
            -- Skip this ability
        elseif API.IsSpellKnown(ability.id) and API.IsSpellUsable(ability.id) then
            -- Check if this ability can dispel the requested type
            for _, dispelType in ipairs(ability.types) do
                if dispelType == debuffType then
                    return ability
                end
            end
        end
    end
    
    return nil
end

-- Process dispels based on combat state
function DispelManager.ProcessDispels(combatState)
    -- Skip if disabled
    if not enableAutoDispel then
        return nil
    end
    
    -- Skip if we recently dispelled
    if GetTime() - lastDispelTime < MIN_DISPEL_INTERVAL then
        return nil
    end
    
    -- Skip if we should only dispel in combat and we're not in combat
    local settings = ConfigRegistry.GetSettings("DispelManager") or { dispelSettings = {} }
    local dispelInCombatOnly = settings.dispelSettings.dispelInCombatOnly
    if dispelInCombatOnly and not combatState.inCombat then
        return nil
    end
    
    -- Get enabled dispel types from settings
    local dispelMagic = settings.dispelSettings.dispelMagic
    local dispelCurse = settings.dispelSettings.dispelCurse
    local dispelDisease = settings.dispelSettings.dispelDisease
    local dispelPoison = settings.dispelSettings.dispelPoison
    
    local enabledTypes = {}
    if dispelMagic then table.insert(enabledTypes, "Magic") end
    if dispelCurse then table.insert(enabledTypes, "Curse") end
    if dispelDisease then table.insert(enabledTypes, "Disease") end
    if dispelPoison then table.insert(enabledTypes, "Poison") end
    
    -- Check party members for dispellable debuffs
    local memberWithDebuff = nil
    local debuffToDispel = nil
    local highestPriority = 9999
    
    -- Sort party members by priority
    local sortedMembers = {}
    for _, member in ipairs(partyMembers) do
        -- Only consider living party members
        if UnitExists(member.unit) and not UnitIsDeadOrGhost(member.unit) then
            table.insert(sortedMembers, member)
        end
    end
    
    table.sort(sortedMembers, function(a, b) return a.priority < b.priority end)
    
    -- Check each party member
    for _, member in ipairs(sortedMembers) do
        -- Get dispellable debuffs on this member
        local memberDebuffs = dispelableDebuffs[member.unit] or {}
        
        -- Check if any debuffs need dispelling
        for _, debuff in ipairs(memberDebuffs) do
            -- Check if this debuff type is enabled for dispelling
            local enabledType = false
            for _, enabledT in ipairs(enabledTypes) do
                if enabledT == debuff.debuffType then
                    enabledType = true
                    break
                end
            end
            
            if enabledType and debuff.priority < highestPriority then
                -- Found a higher priority debuff to dispel
                memberWithDebuff = member
                debuffToDispel = debuff
                highestPriority = debuff.priority
            end
        end
    end
    
    -- If we found a debuff to dispel, get the appropriate dispel ability
    if memberWithDebuff and debuffToDispel then
        local dispelAbility = DispelManager:GetDispelAbilityForType(debuffToDispel.debuffType)
        
        if dispelAbility then
            lastDispelTime = GetTime()
            
            -- Return the dispel action
            return {
                id = dispelAbility.id,
                target = memberWithDebuff.unit
            }
        end
    end
    
    return nil
end

-- Return module
return DispelManager