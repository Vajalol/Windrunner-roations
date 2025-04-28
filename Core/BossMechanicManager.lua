-- BossMechanicManager.lua
-- Detects and responds to boss-specific mechanics
local addonName, WR = ...
local BossMechanicManager = {}
WR.BossMechanicManager = BossMechanicManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry
local MovementManager = WR.MovementManager

-- Local state
local enableMechanicAvoidance = true
local lastMechanicResponse = 0
local MIN_RESPONSE_INTERVAL = 0.5  -- Minimum seconds between mechanic responses
local currentBossID = nil
local currentEncounterID = nil
local currentPhase = 1
local activeMechanics = {}
local detectedEffects = {}
local playerPosition = {x = 0, y = 0, z = 0}
local dangerZones = {}
local safeZones = {}
local mechanicHistory = {}
local MAX_HISTORY_ENTRIES = 20
local raidIDs = {}
local dungeonIDs = {}

-- Types of mechanics
local mechanicTypes = {
    ["FRONTAL"] = {priority = 10, avoidable = true, type = "position"},
    ["GROUND_AOE"] = {priority = 10, avoidable = true, type = "position"},
    ["TARGETED_AOE"] = {priority = 20, avoidable = true, type = "position"},
    ["KNOCKBACK"] = {priority = 30, avoidable = true, type = "ability"},
    ["CHARGE"] = {priority = 10, avoidable = true, type = "position"},
    ["BEAM"] = {priority = 20, avoidable = true, type = "position"},
    ["DOT"] = {priority = 40, avoidable = false, type = "dispel"},
    ["MIND_CONTROL"] = {priority = 20, avoidable = false, type = "cc"},
    ["GRIP"] = {priority = 30, avoidable = false, type = "ability"},
    ["FEAR"] = {priority = 30, avoidable = false, type = "cc"},
    ["STUN"] = {priority = 30, avoidable = false, type = "cc"},
    ["FIXATE"] = {priority = 20, avoidable = true, type = "kite"},
    ["SOAK"] = {priority = 20, avoidable = false, type = "position"},
    ["SPREAD"] = {priority = 20, avoidable = true, type = "position"},
    ["STACK"] = {priority = 20, avoidable = true, type = "position"}
}

-- Database of boss mechanics by boss ID
local bossMechanics = {
    -- Season 2 Raids
    -- Amirdrassil bosses
    [209333] = { -- Gnarlroot
        name = "Gnarlroot",
        encounterID = 2677,
        phases = {
            [1] = {
                mechanics = {
                    {id = 421898, name = "Controlled Burn", type = "GROUND_AOE", timer = 15, duration = 5},
                    {id = 422167, name = "Flaming Pestilence", type = "DOT", timer = 20, dispelType = "Magic"},
                    {id = 421971, name = "Shadow Spines", type = "FRONTAL", timer = 12, duration = 2}
                }
            },
            [2] = {
                startTrigger = {
                    type = "HEALTH_PERCENT",
                    value = 70
                },
                mechanics = {
                    {id = 425816, name = "Doom Cultivation", type = "GROUND_AOE", timer = 25, duration = 6},
                    {id = 421038, name = "Shadowflame", type = "TARGETED_AOE", timer = 18, duration = 3}
                }
            }
        }
    },
    [208478] = { -- Igira the Cruel
        name = "Igira the Cruel",
        encounterID = 2728,
        phases = {
            [1] = {
                mechanics = {
                    {id = 414844, name = "Gathering Torment", type = "STACK", timer = 30, duration = 6},
                    {id = 415624, name = "Heart Stopper", type = "TARGETED_AOE", timer = 15, duration = 3},
                    {id = 414425, name = "Blistering Spear", type = "SPREAD", timer = 22, duration = 5}
                }
            },
            [2] = {
                startTrigger = {
                    type = "HEALTH_PERCENT",
                    value = 65
                },
                mechanics = {
                    {id = 419066, name = "Marked for Torment", type = "FIXATE", timer = 40, duration = 12},
                    {id = 416996, name = "Umbral Destruction", type = "GROUND_AOE", timer = 25, duration = 8}
                }
            }
        }
    },
    
    -- Season 2 Dungeons
    -- Dawn of the Infinite
    [198999] = { -- Chrono-Lord Deios
        name = "Chrono-Lord Deios",
        encounterID = 2673,
        phases = {
            [1] = {
                mechanics = {
                    {id = 410904, name = "Temporal Strike", type = "FRONTAL", timer = 12, duration = 1},
                    {id = 416139, name = "Infinity Nova", type = "GROUND_AOE", timer = 20, duration = 3},
                    {id = 416264, name = "Chronoburst", type = "SPREAD", timer = 15, duration = 4}
                }
            },
            [2] = {
                startTrigger = {
                    type = "HEALTH_PERCENT",
                    value = 60
                },
                mechanics = {
                    {id = 416152, name = "Infinity's End", type = "GROUND_AOE", timer = 30, duration = 6},
                    {id = 416261, name = "Temporal Scar", type = "DOT", timer = 25, dispelType = "Magic"}
                }
            }
        }
    },
    
    -- More bosses would be added here with their mechanics
}

-- Important spellIDs that indicate boss mechanics
local mechanicSpellIDs = {
    -- Ground effects
    [162058] = {type = "GROUND_AOE", name = "Crackling Storm"},
    [153395] = {type = "GROUND_AOE", name = "Toxic Mist"},
    [156852] = {type = "TARGETED_AOE", name = "Acid Torrent"},
    [158315] = {type = "BEAM", name = "Eye of Tectus"},
    
    -- Frontal cone effects
    [156852] = {type = "FRONTAL", name = "Acid Splash"},
    [157592] = {type = "FRONTAL", name = "Molten Torrent"},
    
    -- Knockbacks
    [157322] = {type = "KNOCKBACK", name = "Shockwave Slam"},
    [162066] = {type = "KNOCKBACK", name = "Throw Boulder"},
    
    -- DoTs that need dispelling
    [156086] = {type = "DOT", name = "Acid Torrent", dispelType = "Magic"},
    [155721] = {type = "DOT", name = "Corrupted Blood", dispelType = "Disease"},
    
    -- CC effects
    [154948] = {type = "MIND_CONTROL", name = "Mind Control"},
    [157982] = {type = "FEAR", name = "Terrifying Roar"},
    
    -- Etc. (More would be added in a real implementation)
}

-- Class-specific defensive abilities
local defensiveAbilities = {
    ["WARRIOR"] = {
        { id = 871, name = "Shield Wall", duration = 8, reduction = 40, type = "damage" },
        { id = 12975, name = "Last Stand", duration = 15, healthIncrease = 30, type = "health" },
        { id = 23920, name = "Spell Reflection", duration = 5, type = "reflect" },
        { id = 97462, name = "Rallying Cry", duration = 10, healthIncrease = 15, type = "raid" }
    },
    ["PALADIN"] = {
        { id = 31850, name = "Ardent Defender", duration = 8, reduction = 20, type = "damage" },
        { id = 86659, name = "Guardian of Ancient Kings", duration = 8, reduction = 50, type = "damage" },
        { id = 642, name = "Divine Shield", duration = 8, reduction = 100, type = "immunity" },
        { id = 498, name = "Divine Protection", duration = 8, reduction = 20, type = "magic" }
    },
    ["HUNTER"] = {
        { id = 186265, name = "Aspect of the Turtle", duration = 8, reduction = 100, type = "immunity" },
        { id = 109304, name = "Exhilaration", type = "heal", healPercent = 30 },
        { id = 264735, name = "Survival of the Fittest", duration = 6, reduction = 20, type = "damage" }
    },
    ["ROGUE"] = {
        { id = 31224, name = "Cloak of Shadows", duration = 5, reduction = 100, type = "magic" },
        { id = 5277, name = "Evasion", duration = 10, reduction = 50, type = "physical" },
        { id = 185311, name = "Crimson Vial", type = "heal", healPercent = 20 },
        { id = 1966, name = "Feint", duration = 6, reduction = 40, type = "aoe" }
    },
    ["PRIEST"] = {
        { id = 47585, name = "Dispersion", duration = 6, reduction = 75, type = "damage" },
        { id = 33206, name = "Pain Suppression", duration = 8, reduction = 40, type = "damage" },
        { id = 19236, name = "Desperate Prayer", type = "heal", healPercent = 25 },
        { id = 47788, name = "Guardian Spirit", duration = 10, type = "prevent_death" }
    },
    ["DEATHKNIGHT"] = {
        { id = 48792, name = "Icebound Fortitude", duration = 8, reduction = 30, type = "damage" },
        { id = 55233, name = "Vampiric Blood", duration = 10, healthIncrease = 30, type = "health" },
        { id = 48707, name = "Anti-Magic Shell", duration = 5, reduction = 100, type = "magic" },
        { id = 51052, name = "Anti-Magic Zone", duration = 8, reduction = 20, type = "magic_raid" }
    },
    ["SHAMAN"] = {
        { id = 108271, name = "Astral Shift", duration = 8, reduction = 40, type = "damage" },
        { id = 198838, name = "Earthen Wall Totem", duration = 15, type = "damage_absorb" },
        { id = 30884, name = "Nature's Guardian", type = "heal", healPercent = 20 },
        { id = 207399, name = "Ancestral Protection", duration = 30, type = "prevent_death" }
    },
    ["MAGE"] = {
        { id = 45438, name = "Ice Block", duration = 10, reduction = 100, type = "immunity" },
        { id = 198111, name = "Temporal Shield", duration = 4, type = "time_heal" },
        { id = 113862, name = "Greater Invisibility", duration = 3, reduction = 60, type = "damage" },
        { id = 11426, name = "Ice Barrier", duration = 60, type = "absorb" }
    },
    ["WARLOCK"] = {
        { id = 104773, name = "Unending Resolve", duration = 8, reduction = 40, type = "damage" },
        { id = 108416, name = "Dark Pact", duration = 20, type = "absorb" },
        { id = 6789, name = "Mortal Coil", duration = 3, type = "cc_heal" }
    },
    ["MONK"] = {
        { id = 115203, name = "Fortifying Brew", duration = 15, reduction = 20, healthIncrease = 20, type = "damage" },
        { id = 122278, name = "Dampen Harm", duration = 10, reduction = 20, type = "damage" },
        { id = 122783, name = "Diffuse Magic", duration = 6, reduction = 60, type = "magic" },
        { id = 116849, name = "Life Cocoon", duration = 12, type = "absorb_hot" }
    },
    ["DRUID"] = {
        { id = 22812, name = "Barkskin", duration = 8, reduction = 20, type = "damage" },
        { id = 61336, name = "Survival Instincts", duration = 6, reduction = 50, type = "damage" },
        { id = 102342, name = "Ironbark", duration = 12, reduction = 20, type = "damage_target" },
        { id = 108238, name = "Renewal", type = "heal", healPercent = 30 }
    },
    ["DEMONHUNTER"] = {
        { id = 187827, name = "Metamorphosis", duration = 8, healthIncrease = 30, type = "tank_cd" },
        { id = 198589, name = "Blur", duration = 10, reduction = 20, type = "damage" },
        { id = 196555, name = "Netherwalk", duration = 5, reduction = 100, type = "immunity" },
        { id = 203720, name = "Demon Spikes", duration = 6, reduction = 20, type = "physical" }
    },
    ["EVOKER"] = {
        { id = 363916, name = "Obsidian Scales", duration = 8, reduction = 30, type = "damage" },
        { id = 374348, name = "Renewing Blaze", duration = 8, type = "heal_reduction" },
        { id = 357170, name = "Time Dilation", duration = 8, type = "extend_hots" },
        { id = 370960, name = "Emerald Communion", duration = 5, type = "channel_heal" }
    }
}

-- Initialize module
function BossMechanicManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register events for boss and mechanic detection
    API.RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, groupSize)
        self:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    end)
    
    API.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
        self:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unitTarget, castGUID, spellID)
        if unitTarget == "boss1" or unitTarget == "boss2" or unitTarget == "boss3" or unitTarget == "boss4" then
            self:OnBossSpellCast(unitTarget, castGUID, spellID)
        end
    end)
    
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLog()
    end)
    
    API.RegisterEvent("UNIT_AURA", function(unitTarget)
        if unitTarget == "player" then
            self:CheckPlayerAuras()
        end
    end)
    
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
    
    -- Initial zone check
    self:OnZoneChanged()
    
    API.PrintDebug("Boss Mechanic Manager initialized")
    return true
end

-- Register settings
function BossMechanicManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("BossMechanicManager", {
        mechanicSettings = {
            enableMechanicAvoidance = {
                displayName = "Enable Mechanic Avoidance",
                description = "Automatically avoid boss mechanics",
                type = "toggle",
                default = true
            },
            useDefensivesForMechanics = {
                displayName = "Use Defensives",
                description = "Use defensive abilities for unavoidable mechanics",
                type = "toggle",
                default = true
            },
            mechanicWarningLevel = {
                displayName = "Warning Level",
                description = "Level of audible and visual warnings for mechanics",
                type = "dropdown",
                options = {"Minimal", "Standard", "Verbose"},
                default = 2
            },
            prioritizeSurvival = {
                displayName = "Prioritize Survival",
                description = "Prioritize survival over DPS during dangerous mechanics",
                type = "toggle",
                default = true
            },
            prioritizeRoleMechanics = {
                displayName = "Prioritize Role Mechanics",
                description = "Prioritize mechanics specific to your role (tank, healer, DPS)",
                type = "toggle",
                default = true
            },
            customMechanicResponses = {
                displayName = "Custom Responses",
                description = "Configure custom responses to specific boss mechanics",
                type = "custom",
                default = {}
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("BossMechanicManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function BossMechanicManager:ApplySettings(settings)
    -- Apply mechanic settings
    enableMechanicAvoidance = settings.mechanicSettings.enableMechanicAvoidance
    useDefensivesForMechanics = settings.mechanicSettings.useDefensivesForMechanics
    mechanicWarningLevel = settings.mechanicSettings.mechanicWarningLevel
    prioritizeSurvival = settings.mechanicSettings.prioritizeSurvival
    prioritizeRoleMechanics = settings.mechanicSettings.prioritizeRoleMechanics
    customMechanicResponses = settings.mechanicSettings.customMechanicResponses
    
    API.PrintDebug("Boss Mechanic Manager settings applied")
end

-- Update settings from external source
function BossMechanicManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enableMechanicAvoidance ~= nil then
        enableMechanicAvoidance = newSettings.enableMechanicAvoidance
    end
    
    if newSettings.useDefensivesForMechanics ~= nil then
        useDefensivesForMechanics = newSettings.useDefensivesForMechanics
    end
end

-- Handle zone change
function BossMechanicManager:OnZoneChanged()
    -- Reset boss and encounter data
    currentBossID = nil
    currentEncounterID = nil
    currentPhase = 1
    activeMechanics = {}
    detectedEffects = {}
    dangerZones = {}
    safeZones = {}
    
    -- Get current zone info
    local mapID = C_Map.GetBestMapForUnit("player")
    local instanceID = select(8, GetInstanceInfo())
    
    -- Check if we're in a known raid or dungeon
    local isRaid = false
    local isDungeon = false
    
    -- TODO: Add comprehensive list of raid and dungeon IDs
    for _, id in ipairs(raidIDs) do
        if id == instanceID then
            isRaid = true
            break
        end
    end
    
    for _, id in ipairs(dungeonIDs) do
        if id == instanceID then
            isDungeon = true
            break
        end
    end
    
    -- Update state based on zone
    if isRaid or isDungeon then
        API.PrintDebug("Entered raid or dungeon: " .. GetInstanceInfo())
    else
        API.PrintDebug("Not in a known raid or dungeon")
    end
end

-- Handle encounter start
function BossMechanicManager:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    -- Store encounter info
    currentEncounterID = encounterID
    currentPhase = 1
    
    -- Reset mechanic tracking
    activeMechanics = {}
    detectedEffects = {}
    mechanicHistory = {}
    
    -- Find boss ID based on encounter ID
    for bossID, bossInfo in pairs(bossMechanics) do
        if bossInfo.encounterID == encounterID then
            currentBossID = bossID
            break
        end
    end
    
    -- Initialize active mechanics for phase 1
    if currentBossID and bossMechanics[currentBossID] and bossMechanics[currentBossID].phases[1] then
        for _, mechanic in ipairs(bossMechanics[currentBossID].phases[1].mechanics) do
            table.insert(activeMechanics, {
                id = mechanic.id,
                name = mechanic.name,
                type = mechanic.type,
                timer = mechanic.timer,
                lastSeen = 0,
                duration = mechanic.duration or 3,
                dispelType = mechanic.dispelType
            })
        end
    end
    
    API.PrintDebug("Encounter started: " .. encounterName .. " (ID: " .. encounterID .. ")")
end

-- Handle encounter end
function BossMechanicManager:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    -- Reset state
    currentBossID = nil
    currentEncounterID = nil
    currentPhase = 1
    activeMechanics = {}
    detectedEffects = {}
    dangerZones = {}
    safeZones = {}
    
    API.PrintDebug("Encounter ended: " .. encounterName)
end

-- Handle boss spell cast
function BossMechanicManager:OnBossSpellCast(unitTarget, castGUID, spellID)
    -- Check if this is a known mechanic
    local mechanicInfo = nil
    
    -- Check boss-specific mechanics first
    if currentBossID and bossMechanics[currentBossID] and bossMechanics[currentBossID].phases[currentPhase] then
        for _, mechanic in ipairs(bossMechanics[currentBossID].phases[currentPhase].mechanics) do
            if mechanic.id == spellID then
                mechanicInfo = mechanic
                break
            end
        end
    end
    
    -- If not found in boss-specific mechanics, check general mechanics
    if not mechanicInfo and mechanicSpellIDs[spellID] then
        mechanicInfo = mechanicSpellIDs[spellID]
    end
    
    -- If we found a mechanic, process it
    if mechanicInfo then
        -- Add to detected effects
        local effect = {
            id = spellID,
            name = mechanicInfo.name,
            type = mechanicInfo.type,
            source = unitTarget,
            startTime = GetTime(),
            duration = mechanicInfo.duration or 3,
            endTime = GetTime() + (mechanicInfo.duration or 3),
            priority = mechanicTypes[mechanicInfo.type] and mechanicTypes[mechanicInfo.type].priority or 50,
            dispelType = mechanicInfo.dispelType
        }
        
        table.insert(detectedEffects, effect)
        
        -- Update mechanic last seen time
        for _, mechanic in ipairs(activeMechanics) do
            if mechanic.id == spellID then
                mechanic.lastSeen = GetTime()
                break
            end
        end
        
        -- Add to history
        table.insert(mechanicHistory, {
            id = spellID,
            name = mechanicInfo.name,
            type = mechanicInfo.type,
            time = GetTime()
        })
        
        -- Trim history if it gets too long
        while #mechanicHistory > MAX_HISTORY_ENTRIES do
            table.remove(mechanicHistory, 1)
        end
        
        -- Create danger zone if applicable
        if mechanicInfo.type == "GROUND_AOE" or mechanicInfo.type == "TARGETED_AOE" or mechanicInfo.type == "FRONTAL" or mechanicInfo.type == "BEAM" then
            -- Get position of effect
            local effectPosition = {x = 0, y = 0, z = 0}
            
            -- Different positioning based on mechanic type
            if mechanicInfo.type == "GROUND_AOE" or mechanicInfo.type == "TARGETED_AOE" then
                -- Try to get target position
                local targetUnit = "target"
                if effect.source ~= "boss1" then
                    targetUnit = effect.source
                end
                
                -- Get position of target
                if API.GetObjectPosition then
                    local x, y, z = API.GetObjectPosition(targetUnit)
                    if x and y then
                        effectPosition.x = x
                        effectPosition.y = y
                        effectPosition.z = z or 0
                    end
                end
            elseif mechanicInfo.type == "FRONTAL" or mechanicInfo.type == "BEAM" then
                -- For frontal/beam effects, we need source position and facing
                local sourceUnit = effect.source
                local sourceFacing = 0
                
                -- Get position of source
                if API.GetObjectPosition then
                    local x, y, z = API.GetObjectPosition(sourceUnit)
                    if x and y then
                        effectPosition.x = x
                        effectPosition.y = y
                        effectPosition.z = z or 0
                    end
                end
                
                -- TODO: Get facing of source
                -- This would be more sophisticated in a real implementation
            end
            
            -- Create danger zone
            local radius = 8  -- Default radius
            if mechanicInfo.radius then
                radius = mechanicInfo.radius
            elseif mechanicInfo.type == "FRONTAL" then
                radius = 15  -- Frontal is usually larger
            elseif mechanicInfo.type == "BEAM" then
                radius = 40  -- Beam is usually much larger
            end
            
            local dangerZone = {
                x = effectPosition.x,
                y = effectPosition.y,
                z = effectPosition.z,
                radius = radius,
                type = mechanicInfo.type,
                startTime = GetTime(),
                endTime = GetTime() + (mechanicInfo.duration or 3)
            }
            
            table.insert(dangerZones, dangerZone)
        end
        
        API.PrintDebug("Detected boss mechanic: " .. mechanicInfo.name .. " (" .. mechanicInfo.type .. ")")
    end
end

-- Process combat log for additional mechanic detection
function BossMechanicManager:ProcessCombatLog()
    local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Check if this is a known mechanic
    if mechanicSpellIDs[spellID] then
        local mechanicInfo = mechanicSpellIDs[spellID]
        
        -- Process based on event type
        if eventType == "SPELL_CAST_START" or eventType == "SPELL_CAST_SUCCESS" then
            -- Similar to OnBossSpellCast but with combat log info
            -- Add to detected effects
            local effect = {
                id = spellID,
                name = mechanicInfo.name,
                type = mechanicInfo.type,
                source = sourceName,
                startTime = GetTime(),
                duration = mechanicInfo.duration or 3,
                endTime = GetTime() + (mechanicInfo.duration or 3),
                priority = mechanicTypes[mechanicInfo.type] and mechanicTypes[mechanicInfo.type].priority or 50,
                dispelType = mechanicInfo.dispelType
            }
            
            table.insert(detectedEffects, effect)
            
            API.PrintDebug("Detected mechanic from combat log: " .. mechanicInfo.name)
        elseif eventType == "SPELL_AURA_APPLIED" and destGUID == UnitGUID("player") then
            -- Player was affected by a mechanic
            self:OnPlayerAffectedByMechanic(spellID, mechanicInfo)
        end
    end
    
    -- Check for phase transitions based on boss health
    if currentBossID and bossMechanics[currentBossID] then
        local bossUnit = "boss1"
        if UnitExists(bossUnit) then
            local bossHealth = UnitHealth(bossUnit) / UnitHealthMax(bossUnit) * 100
            
            -- Check for phase transitions
            for phaseNum, phaseInfo in pairs(bossMechanics[currentBossID].phases) do
                if phaseNum > currentPhase and phaseInfo.startTrigger and phaseInfo.startTrigger.type == "HEALTH_PERCENT" and bossHealth <= phaseInfo.startTrigger.value then
                    -- Transition to new phase
                    self:TransitionToPhase(phaseNum)
                    break
                end
            end
        end
    end
end

-- Check player auras for mechanic effects
function BossMechanicManager:CheckPlayerAuras()
    local i = 1
    while true do
        local name, _, _, _, _, _, _, _, _, spellID = UnitAura("player", i, "HARMFUL")
        if not name then break end
        
        -- Check if this is a known mechanic
        if mechanicSpellIDs[spellID] then
            local mechanicInfo = mechanicSpellIDs[spellID]
            
            -- Player is affected by a mechanic
            self:OnPlayerAffectedByMechanic(spellID, mechanicInfo)
        end
        
        i = i + 1
    end
end

-- Handle player being affected by a mechanic
function BossMechanicManager:OnPlayerAffectedByMechanic(spellID, mechanicInfo)
    -- Add to detected effects with higher priority since it's affecting player
    local effect = {
        id = spellID,
        name = mechanicInfo.name,
        type = mechanicInfo.type,
        affectingPlayer = true,
        startTime = GetTime(),
        duration = mechanicInfo.duration or 3,
        endTime = GetTime() + (mechanicInfo.duration or 3),
        priority = (mechanicTypes[mechanicInfo.type] and mechanicTypes[mechanicInfo.type].priority or 50) - 10,  -- Higher priority (lower number)
        dispelType = mechanicInfo.dispelType
    }
    
    table.insert(detectedEffects, effect)
    
    -- Add to history
    table.insert(mechanicHistory, {
        id = spellID,
        name = mechanicInfo.name,
        type = mechanicInfo.type,
        time = GetTime(),
        affectedPlayer = true
    })
    
    -- Trim history if it gets too long
    while #mechanicHistory > MAX_HISTORY_ENTRIES do
        table.remove(mechanicHistory, 1)
    end
    
    API.PrintDebug("Player affected by mechanic: " .. mechanicInfo.name)
end

-- Transition to a new boss phase
function BossMechanicManager:TransitionToPhase(newPhase)
    -- Update phase
    currentPhase = newPhase
    
    -- Clear old mechanics
    activeMechanics = {}
    
    -- Add new mechanics for this phase
    if bossMechanics[currentBossID] and bossMechanics[currentBossID].phases[newPhase] then
        for _, mechanic in ipairs(bossMechanics[currentBossID].phases[newPhase].mechanics) do
            table.insert(activeMechanics, {
                id = mechanic.id,
                name = mechanic.name,
                type = mechanic.type,
                timer = mechanic.timer,
                lastSeen = 0,
                duration = mechanic.duration or 3,
                dispelType = mechanic.dispelType
            })
        end
    end
    
    API.PrintDebug("Transitioned to phase " .. newPhase)
end

-- Get the most appropriate defensive ability for a mechanic
function BossMechanicManager:GetDefensiveForMechanic(mechanicType)
    -- Skip if defensive usage disabled
    if not useDefensivesForMechanics then
        return nil
    end
    
    -- Get player class
    local playerClass = select(2, UnitClass("player"))
    
    -- Get defensive abilities for this class
    local abilities = defensiveAbilities[playerClass]
    if not abilities then
        return nil
    end
    
    -- Filter abilities by usability
    local usableAbilities = {}
    for _, ability in ipairs(abilities) do
        -- Check if spell is known and usable
        if API.IsSpellKnown(ability.id) and API.IsSpellUsable(ability.id) then
            -- Calculate a priority score based on mechanic type and ability properties
            local priorityScore = 50
            
            -- Different mechanics need different defensives
            if mechanicType == "GROUND_AOE" or mechanicType == "TARGETED_AOE" then
                -- AoE damage - prioritize AoE reduction or immunities
                if ability.type == "immunity" then
                    priorityScore = 10
                elseif ability.type == "aoe" then
                    priorityScore = 20
                elseif ability.type == "damage" then
                    priorityScore = 30
                end
            elseif mechanicType == "DOT" then
                -- DoT damage - prioritize immunities or healing
                if ability.type == "immunity" then
                    priorityScore = 10
                elseif ability.type == "heal" or ability.type == "heal_reduction" then
                    priorityScore = 20
                elseif ability.type == "damage" then
                    priorityScore = 30
                end
            elseif mechanicType == "FRONTAL" or mechanicType == "BEAM" then
                -- Frontal attacks - prioritize immunities or physical reduction
                if ability.type == "immunity" then
                    priorityScore = 10
                elseif ability.type == "physical" then
                    priorityScore = 20
                elseif ability.type == "damage" then
                    priorityScore = 30
                end
            elseif mechanicType == "MIND_CONTROL" or mechanicType == "FEAR" or mechanicType == "STUN" then
                -- CC effects - need specific anti-CC abilities
                if ability.type == "immunity" then
                    priorityScore = 10
                elseif ability.type == "reflect" then
                    priorityScore = 20
                end
            end
            
            -- Store with priority
            table.insert(usableAbilities, {
                id = ability.id,
                name = ability.name,
                type = ability.type,
                priority = priorityScore
            })
        end
    end
    
    -- Sort by priority (lower = higher priority)
    table.sort(usableAbilities, function(a, b) return a.priority < b.priority end)
    
    -- Return the best ability, or nil if none found
    return usableAbilities[1]
end

-- Clean up expired effects and zones
function BossMechanicManager:CleanupExpired()
    local currentTime = GetTime()
    
    -- Clean up detected effects
    for i = #detectedEffects, 1, -1 do
        if detectedEffects[i].endTime <= currentTime then
            table.remove(detectedEffects, i)
        end
    end
    
    -- Clean up danger zones
    for i = #dangerZones, 1, -1 do
        if dangerZones[i].endTime <= currentTime then
            table.remove(dangerZones, i)
        end
    end
end

-- Process mechanic avoidance based on combat state
function BossMechanicManager.ProcessMechanics(combatState)
    -- Skip if disabled
    if not enableMechanicAvoidance then
        return nil
    end
    
    -- Skip if too soon after last response
    if GetTime() - lastMechanicResponse < MIN_RESPONSE_INTERVAL then
        return nil
    end
    
    -- Clean up expired effects and zones
    BossMechanicManager:CleanupExpired()
    
    -- Get the highest priority active effect
    local highestPriorityEffect = nil
    local highestPriority = 999
    
    for _, effect in ipairs(detectedEffects) do
        if effect.priority < highestPriority then
            highestPriorityEffect = effect
            highestPriority = effect.priority
        end
    end
    
    -- If we found an effect, respond to it
    if highestPriorityEffect then
        -- Determine the response based on mechanic type
        local mechanicType = highestPriorityEffect.type
        local mechanicTypeInfo = mechanicTypes[mechanicType]
        
        if not mechanicTypeInfo then
            return nil
        end
        
        -- Check if this type of mechanic is avoidable
        if mechanicTypeInfo.avoidable and mechanicTypeInfo.type == "position" then
            -- We should move out of this mechanic
            -- Check if player is in a danger zone
            local playerPos = {x = 0, y = 0, z = 0}
            
            -- Get player position
            if API.GetObjectPosition then
                local x, y, z = API.GetObjectPosition("player")
                if x and y then
                    playerPos.x = x
                    playerPos.y = y
                    playerPos.z = z or 0
                end
            end
            
            local inDanger = false
            for _, zone in ipairs(dangerZones) do
                local distance = math.sqrt((zone.x - playerPos.x)^2 + (zone.y - playerPos.y)^2)
                if distance < zone.radius then
                    inDanger = true
                    break
                end
            end
            
            -- If in danger, move out
            if inDanger and MovementManager then
                -- Find safe position
                local safePos = MovementManager:FindSafePosition(playerPos, "ranged")
                
                if safePos then
                    lastMechanicResponse = GetTime()
                    
                    -- Return movement command
                    return {
                        move = true,
                        x = safePos.x,
                        y = safePos.y,
                        z = safePos.z,
                        priority = "HIGH"  -- High priority movement
                    }
                end
            end
        elseif not mechanicTypeInfo.avoidable or mechanicTypeInfo.type == "ability" then
            -- For unavoidable mechanics, use defensives
            local defensiveAbility = BossMechanicManager:GetDefensiveForMechanic(mechanicType)
            
            if defensiveAbility then
                lastMechanicResponse = GetTime()
                
                -- Return defensive ability usage
                return {
                    id = defensiveAbility.id,
                    target = "player",
                    priority = "HIGH"  -- High priority ability usage
                }
            end
        elseif mechanicTypeInfo.type == "dispel" and highestPriorityEffect.dispelType then
            -- For dispellable effects, trigger dispel
            -- This would integrate with the DispelManager
            lastMechanicResponse = GetTime()
            
            -- Return dispel request
            return {
                dispel = true,
                type = highestPriorityEffect.dispelType,
                target = "player",
                priority = "HIGH"  -- High priority dispel
            }
        end
    end
    
    return nil
end

-- Return module
return BossMechanicManager