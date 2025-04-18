------------------------------------------
-- WindrunnerRotations - PvP Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local PvPManager = {}
WR.PvPManager = PvPManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local MachineLearning = WR.MachineLearning
local InterruptManager = WR.InterruptManager
local TargetPrioritySystem = WR.TargetPrioritySystem

-- Data storage
local inPvP = false
local inArena = false
local inBattleground = false
local isPvPTalented = false
local pvpZoneType = nil
local arenaTeamSize = 0
local enemyArenaUnits = {}
local friendlyArenaUnits = {}
local burstEnabled = false
local burstStart = 0
local burstDuration = 15 -- 15 seconds by default
local ccBreakersAvailable = {}
local ccTracker = {}
local drTracker = {}
local enemySpecializations = {}
local enemyClasses = {}
local importantEnemyCDs = {}
local currentPvPTemplate = nil
local activePvPRotation = "Default"
local inRatedMatch = false
local currentBracket = nil
local enemyComposition = {}
local ZONE_TYPE_ARENA = "arena"
local ZONE_TYPE_BATTLEGROUND = "battleground"
local ZONE_TYPE_WORLD = "world"
local DR_CATEGORIES = {
    "stun", "silence", "disorient", "incapacitate", "fear", "horror", "root", "knockback"
}

-- Diminishing returns states
local DR_STATE_FULL = 1     -- 100% duration
local DR_STATE_HALF = 2     -- 50% duration
local DR_STATE_QUARTER = 3  -- 25% duration
local DR_STATE_IMMUNE = 4   -- 0% duration (immune)

-- Initialize the PvP Manager
function PvPManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize PvP data
    self:InitializePvPData()
    
    -- Update current PvP state
    self:UpdatePvPState()
    
    -- Set up CC tracker
    self:SetupCCTracker()
    
    API.PrintDebug("PvP Manager initialized")
    return true
end

-- Register settings
function PvPManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("PvPManager", {
        generalSettings = {
            enablePvPMode = {
                displayName = "Enable PvP Mode",
                description = "Automatically enable specialized PvP rotation when in PvP",
                type = "toggle",
                default = true
            },
            pvpRotationMode = {
                displayName = "PvP Rotation Mode",
                description = "Select PvP rotation mode",
                type = "dropdown",
                options = {"Default", "Offensive", "Defensive", "Balanced", "Custom"},
                default = "Default"
            },
            autoDetectComposition = {
                displayName = "Auto-Detect Enemy Composition",
                description = "Automatically detect and adapt to enemy team composition",
                type = "toggle",
                default = true
            },
            trackImportantEnemyCDs = {
                displayName = "Track Important Enemy Cooldowns",
                description = "Track high-impact enemy cooldowns and adjust strategy",
                type = "toggle",
                default = true
            }
        },
        arenaBehavior = {
            arenaSpecificRotations = {
                displayName = "Arena-Specific Rotations",
                description = "Use specialized rotations for different arena team sizes",
                type = "toggle",
                default = true
            },
            adaptToEnemyHealer = {
                displayName = "Adapt to Enemy Healer",
                description = "Focus offensive pressure on healers based on their class",
                type = "toggle",
                default = true
            },
            adaptToEnemyComp = {
                displayName = "Adapt to Enemy Composition",
                description = "Adapt playstyle to common comps (cleave, RMP, etc.)",
                type = "toggle",
                default = true
            },
            enableFocusProtection = {
                displayName = "Focus Teammate Protection",
                description = "Enable teammate protection when they are focused",
                type = "toggle",
                default = true
            }
        },
        burstSettings = {
            enableBurstMode = {
                displayName = "Enable Burst Mode",
                description = "Enable coordinated burst damage phases",
                type = "toggle",
                default = true
            },
            burstModeKey = {
                displayName = "Burst Mode Key",
                description = "Keybind to activate burst mode",
                type = "keybind",
                default = "F1"
            },
            burstDuration = {
                displayName = "Burst Duration",
                description = "Duration of burst mode in seconds",
                type = "slider",
                min = 5,
                max = 30,
                step = 1,
                default = 15
            },
            ignoreManaInBurst = {
                displayName = "Ignore Mana in Burst",
                description = "Ignore mana conservation during burst phases",
                type = "toggle",
                default = true
            },
            burstAfterCC = {
                displayName = "Burst After CC",
                description = "Auto-activate burst when target is controlled",
                type = "toggle",
                default = true
            }
        },
        ccSettings = {
            enableCCTracking = {
                displayName = "Enable CC Tracking",
                description = "Track DR categories and CC durations",
                type = "toggle",
                default = true
            },
            enableCCChains = {
                displayName = "Enable CC Chains",
                description = "Suggest optimal CC chains based on DR",
                type = "toggle",
                default = true
            },
            enableCCBreaking = {
                displayName = "Enable CC Breaking",
                description = "Automatically suggest breaking CC on teammates",
                type = "toggle",
                default = true
            },
            prioritizeCCTarget = {
                displayName = "Prioritize CC Target",
                description = "Increased damage priority on CC'd targets",
                type = "toggle",
                default = true
            }
        },
        defensiveSettings = {
            defensiveMode = {
                displayName = "Defensive Mode",
                description = "How defensively the rotation should play",
                type = "dropdown",
                options = {"Normal", "Conservative", "Aggressive", "Auto-Adapt"},
                default = "Auto-Adapt"
            },
            defensiveThreshold = {
                displayName = "Defensive Threshold",
                description = "Health percentage to use defensive abilities",
                type = "slider",
                min = 0,
                max = 100,
                step = 5,
                default = 50
            },
            prioritizeDefensiveCDs = {
                displayName = "Prioritize Defensive CDs",
                description = "Give higher priority to defensive cooldowns in PvP",
                type = "toggle",
                default = true
            },
            protectTeammates = {
                displayName = "Protect Teammates",
                description = "Use supportive abilities on teammates",
                type = "toggle",
                default = true
            }
        },
        pvpTemplates = {
            enableCustomTemplates = {
                displayName = "Enable Custom Templates",
                description = "Use custom PvP rotation templates",
                type = "toggle",
                default = true
            },
            activeTemplate = {
                displayName = "Active Template",
                description = "Currently active PvP template",
                type = "dropdown",
                options = {"Default", "Battleground", "2v2", "3v3", "RBG"},
                default = "Default"
            },
            editTemplates = {
                displayName = "Edit Templates",
                description = "Edit PvP rotation templates",
                type = "button",
                default = nil
            }
        }
    })
end

-- Register for events
function PvPManager:RegisterEvents()
    -- Register for arena events
    API.RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", function()
        self:OnArenaOpponentSpecsReady()
    end)
    
    API.RegisterEvent("ARENA_OPPONENT_UPDATE", function(unit, updateReason)
        self:OnArenaOpponentUpdate(unit, updateReason)
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_BATTLEGROUND", function()
        self:OnEnterBattleground()
    end)
    
    -- Register for zone changes
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:UpdatePvPState()
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:UpdatePvPState()
    end)
    
    -- Register for unit events
    API.RegisterEvent("UNIT_AURA", function(unit)
        self:OnUnitAuraChanged(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
        self:OnUnitSpellcastSucceeded(unit, spellID)
    end)
    
    -- Register for combat log events
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for PvP talents
    API.RegisterEvent("PLAYER_PVP_TALENT_UPDATE", function()
        self:OnPvPTalentUpdate()
    end)
    
    -- Register for rated PvP info
    API.RegisterEvent("PVP_MATCH_ACTIVE", function()
        self:OnPvPMatchActive()
    end)
    
    API.RegisterEvent("PVP_MATCH_COMPLETE", function()
        self:OnPvPMatchComplete()
    end)
}

-- Initialize PvP data
function PvPManager:InitializePvPData()
    -- Initialize arena units
    for i = 1, 5 do
        enemyArenaUnits["arena" .. i] = {
            guid = nil,
            class = nil,
            spec = nil,
            health = 100,
            isHealer = false,
            isDPS = false,
            isTank = false
        }
        
        friendlyArenaUnits["party" .. i] = {
            guid = nil,
            class = nil,
            spec = nil,
            health = 100,
            isHealer = false,
            isDPS = false,
            isTank = false
        }
    end
    
    -- Add player to friendly units
    friendlyArenaUnits["player"] = {
        guid = UnitGUID("player"),
        class = select(2, UnitClass("player")),
        spec = API.GetActiveSpecID(),
        health = 100,
        isHealer = self:IsHealerSpec(API.GetActiveSpecID()),
        isDPS = not self:IsHealerSpec(API.GetActiveSpecID()),
        isTank = self:IsTankSpec(API.GetActiveSpecID())
    }
    
    -- Initialize CC breakers
    self:InitializeCCBreakers()
    
    -- Initialize important enemy cooldowns to track
    self:InitializeImportantEnemyCooldowns()
}

-- Initialize CC breakers
function PvPManager:InitializeCCBreakers()
    ccBreakersAvailable = {
        -- General
        everyManForHimself = {spellID = 59752, name = "Every Man for Himself", race = "Human", available = false},
        iceBlock = {spellID = 45438, name = "Ice Block", class = "MAGE", available = false},
        divineShield = {spellID = 642, name = "Divine Shield", class = "PALADIN", available = false},
        blessingOfProtection = {spellID = 1022, name = "Blessing of Protection", class = "PALADIN", available = false},
        cloak = {spellID = 31224, name = "Cloak of Shadows", class = "ROGUE", available = false},
        trinket = {spellID = 42292, name = "PvP Trinket", available = false},
        adaptation = {spellID = 214027, name = "Adaptation", available = false},
        berserk = {spellID = 227847, name = "Berserk", class = "DRUID", available = false},
        wildCharge = {spellID = 102401, name = "Wild Charge", class = "DRUID", available = false},
        
        -- Check if player has these abilities
        -- Only set available = true for abilities the player actually has
    }
    
    -- Check which ones the player actually has
    local playerClass = select(2, UnitClass("player"))
    local playerRace = select(2, UnitRace("player"))
    
    for key, breaker in pairs(ccBreakersAvailable) do
        -- Check class-specific breakers
        if breaker.class and breaker.class == playerClass and IsSpellKnown(breaker.spellID) then
            ccBreakersAvailable[key].available = true
        end
        
        -- Check race-specific breakers
        if breaker.race and breaker.race == playerRace and IsSpellKnown(breaker.spellID) then
            ccBreakersAvailable[key].available = true
        end
        
        -- Check general breakers (trinket, adaptation)
        if not breaker.class and not breaker.race then
            -- This would check for PvP trinkets or talents in a real addon
            -- For implementation simplicity, we'll set them to true
            ccBreakersAvailable[key].available = true
        end
    end
}

-- Initialize important enemy cooldowns
function PvPManager:InitializeImportantEnemyCooldowns()
    -- High-priority enemy cooldowns to track
    importantEnemyCDs = {
        -- Priest
        [47585] = {name = "Dispersion", duration = 6, importance = "high", class = "PRIEST", spec = 3},
        [64843] = {name = "Divine Hymn", duration = 8, importance = "high", class = "PRIEST", spec = 2},
        [10060] = {name = "Power Infusion", duration = 20, importance = "medium", class = "PRIEST", spec = 0},
        [33206] = {name = "Pain Suppression", duration = 8, importance = "high", class = "PRIEST", spec = 1},
        
        -- Paladin
        [31884] = {name = "Avenging Wrath", duration = 20, importance = "high", class = "PALADIN", spec = 0},
        [642] = {name = "Divine Shield", duration = 8, importance = "high", class = "PALADIN", spec = 0},
        [1022] = {name = "Blessing of Protection", duration = 10, importance = "high", class = "PALADIN", spec = 0},
        [6940] = {name = "Blessing of Sacrifice", duration = 12, importance = "medium", class = "PALADIN", spec = 0},
        
        -- Mage
        [12472] = {name = "Icy Veins", duration = 20, importance = "high", class = "MAGE", spec = 3},
        [45438] = {name = "Ice Block", duration = 10, importance = "high", class = "MAGE", spec = 0},
        [12042] = {name = "Arcane Power", duration = 10, importance = "high", class = "MAGE", spec = 1},
        [190319] = {name = "Combustion", duration = 10, importance = "high", class = "MAGE", spec = 2},
        
        -- Warrior
        [1719] = {name = "Recklessness", duration = 10, importance = "high", class = "WARRIOR", spec = 0},
        [871] = {name = "Shield Wall", duration = 8, importance = "high", class = "WARRIOR", spec = 3},
        [118038] = {name = "Die by the Sword", duration = 8, importance = "medium", class = "WARRIOR", spec = 1},
        [97462] = {name = "Rallying Cry", duration = 10, importance = "medium", class = "WARRIOR", spec = 0},
        
        -- Druid
        [29166] = {name = "Innervate", duration = 10, importance = "medium", class = "DRUID", spec = 0},
        [194223] = {name = "Celestial Alignment", duration = 20, importance = "high", class = "DRUID", spec = 1},
        [106951] = {name = "Berserk", duration = 15, importance = "high", class = "DRUID", spec = 2},
        [61336] = {name = "Survival Instincts", duration = 6, importance = "high", class = "DRUID", spec = 0},
        
        -- Rogue
        [31224] = {name = "Cloak of Shadows", duration = 5, importance = "high", class = "ROGUE", spec = 0},
        [5277] = {name = "Evasion", duration = 10, importance = "high", class = "ROGUE", spec = 0},
        [185311] = {name = "Crimson Vial", duration = 4, importance = "low", class = "ROGUE", spec = 0},
        [13750] = {name = "Adrenaline Rush", duration = 20, importance = "high", class = "ROGUE", spec = 2},
        
        -- Warlock
        [196098] = {name = "Soul Harvest", duration = 20, importance = "high", class = "WARLOCK", spec = 0},
        [104773] = {name = "Unending Resolve", duration = 8, importance = "high", class = "WARLOCK", spec = 0},
        [113860] = {name = "Dark Soul: Misery", duration = 20, importance = "high", class = "WARLOCK", spec = 1},
        [113858] = {name = "Dark Soul: Instability", duration = 20, importance = "high", class = "WARLOCK", spec = 3},
        
        -- And many more... (this is just a sample)
    }
}

-- Update PvP state
function PvPManager:UpdatePvPState()
    -- Check if we're in PvP combat zone
    local inArena = IsActiveBattlefieldArena()
    local inBattleground = UnitInBattleground("player")
    local warModeEnabled = C_PvP.IsWarModeDesired()
    
    -- Set PvP state
    inPvP = inArena or inBattleground or warModeEnabled
    self.inArena = inArena
    self.inBattleground = inBattleground
    
    -- Determine zone type
    if inArena then
        pvpZoneType = ZONE_TYPE_ARENA
        -- Get arena team size
        arenaTeamSize = select(2, IsActiveBattlefieldArena())
    elseif inBattleground then
        pvpZoneType = ZONE_TYPE_BATTLEGROUND
    else
        pvpZoneType = ZONE_TYPE_WORLD
    end
    
    -- Update PvP talents
    self:UpdatePvPTalents()
    
    -- Set proper rotation template based on settings
    self:SelectPvPTemplate()
    
    -- Update UI
    self:UpdatePvPUI()
    
    API.PrintDebug("PvP state updated: " .. (inPvP and "In PvP" or "Not in PvP") .. ", Zone: " .. pvpZoneType)
}

-- Update PvP talents
function PvPManager:UpdatePvPTalents()
    -- Check if PvP talents are active
    isPvPTalented = C_PvP.IsActiveBattlefield() or C_PvP.IsWarModeDesired()
    
    if isPvPTalented then
        API.PrintDebug("PvP talents active")
        
        -- This would scan player's PvP talents in a real addon
        -- For implementation simplicity, we'll just set a flag
    else
        API.PrintDebug("PvP talents inactive")
    end
}

-- Select PvP template
function PvPManager:SelectPvPTemplate()
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    -- Use manual template if custom templates are enabled
    if settings.pvpTemplates.enableCustomTemplates then
        currentPvPTemplate = settings.pvpTemplates.activeTemplate
    else
        -- Auto-select based on instance type
        if pvpZoneType == ZONE_TYPE_ARENA then
            if arenaTeamSize == 2 then
                currentPvPTemplate = "2v2"
            elseif arenaTeamSize == 3 then
                currentPvPTemplate = "3v3"
            else
                currentPvPTemplate = "Default"
            end
        elseif pvpZoneType == ZONE_TYPE_BATTLEGROUND then
            currentPvPTemplate = "Battleground"
            
            -- Check if RBG
            if C_PvP.IsRatedBattleground() then
                currentPvPTemplate = "RBG"
            end
        else
            currentPvPTemplate = "Default"
        end
    end
    
    -- Set active PvP rotation mode
    activePvPRotation = settings.generalSettings.pvpRotationMode
    
    API.PrintDebug("Selected PvP template: " .. currentPvPTemplate .. ", Rotation mode: " .. activePvPRotation)
}

-- Update PvP UI
function PvPManager:UpdatePvPUI()
    -- This would update the PvP-specific UI elements
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("PvP UI updated")
}

-- Set up CC tracker
function PvPManager:SetupCCTracker()
    -- Initialize CC tracker
    for _, category in ipairs(DR_CATEGORIES) do
        drTracker[category] = {}
    end
    
    -- Add event to track CC application and removal
    -- This is done through the combat log event
}

-- Process combat log event
function PvPManager:ProcessCombatLogEvent(...)
    -- Skip processing if not in PvP
    if not inPvP then
        return
    end
    
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName = ...
    
    -- Track important spellcasts
    if event == "SPELL_CAST_SUCCESS" then
        -- Check if this is an important enemy cooldown
        self:TrackImportantEnemyCooldown(sourceGUID, sourceName, sourceFlags, spellID)
        
        -- Check for CC breakers
        self:CheckCCBreaker(sourceGUID, sourceName, sourceFlags, spellID)
    end
    
    -- Track CC application/removal
    if event == "SPELL_AURA_APPLIED" and self:IsCCEffect(spellID) then
        -- Add to CC tracker
        self:AddCCToTracker(destGUID, destName, destFlags, spellID, spellName)
        
        -- Check for CC chains
        self:CheckCCChains(destGUID, spellID)
    end
    
    if event == "SPELL_AURA_REMOVED" and self:IsCCEffect(spellID) then
        -- Remove from CC tracker
        self:RemoveCCFromTracker(destGUID, spellID)
    end
    
    -- Track arena unit damage
    if (event == "SPELL_DAMAGE" or event == "RANGE_DAMAGE" or event == "SWING_DAMAGE") and self:IsArenaUnit(destGUID) then
        -- Update unit health
        self:UpdateArenaUnitHealth(destGUID)
    end
    
    -- Track arena unit healing
    if event == "SPELL_HEAL" and self:IsArenaUnit(destGUID) then
        -- Update unit health
        self:UpdateArenaUnitHealth(destGUID)
    end
}

-- Track important enemy cooldown
function PvPManager:TrackImportantEnemyCooldown(sourceGUID, sourceName, sourceFlags, spellID)
    -- Skip if not an enemy
    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
        return
    end
    
    -- Skip if not in importantEnemyCDs list
    if not importantEnemyCDs[spellID] then
        return
    end
    
    -- Log important enemy cooldown
    local cdInfo = importantEnemyCDs[spellID]
    local now = GetTime()
    
    -- Record the cooldown use
    API.PrintDebug("Enemy " .. sourceName .. " used " .. cdInfo.name .. " (importance: " .. cdInfo.importance .. ")")
    
    -- Store in tracker
    if not enemySpecializations[sourceGUID] then
        enemySpecializations[sourceGUID] = {
            name = sourceName,
            guid = sourceGUID,
            cooldowns = {}
        }
    end
    
    enemySpecializations[sourceGUID].cooldowns[spellID] = {
        name = cdInfo.name,
        startTime = now,
        endTime = now + cdInfo.duration,
        importance = cdInfo.importance
    }
    
    -- Based on the cooldown's importance, we might want to adjust our strategy
    if cdInfo.importance == "high" then
        -- For high importance cooldowns (i.e. Ice Block, Divine Shield, Dispersion)
        -- we might want to switch targets or play defensively
        self:AdjustStrategyForEnemyCooldown(cdInfo, sourceGUID, sourceName)
    end
}

-- Adjust strategy for enemy cooldown
function PvPManager:AdjustStrategyForEnemyCooldown(cdInfo, sourceGUID, sourceName)
    -- This would adjust the rotation strategy based on the enemy cooldown
    -- For implementation simplicity, we'll just print a debug message
    
    local currentTarget = UnitGUID("target")
    
    if currentTarget == sourceGUID then
        -- If this is our current target and they used a defensive, we might want to switch
        if cdInfo.name == "Ice Block" or cdInfo.name == "Divine Shield" or cdInfo.name == "Dispersion" then
            API.PrintDebug("Target used major defensive: " .. cdInfo.name .. ". Consider target switch!")
        end
    end
}

-- Check CC breaker
function PvPManager:CheckCCBreaker(sourceGUID, sourceName, sourceFlags, spellID)
    -- Skip if not friendly
    if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 then
        return
    end
    
    -- Check if this was a CC breaker
    for key, breaker in pairs(ccBreakersAvailable) do
        if breaker.spellID == spellID then
            API.PrintDebug("CC breaker used: " .. breaker.name .. " by " .. sourceName)
            
            -- Update availability
            ccBreakersAvailable[key].available = false
            
            -- Schedule CD tracking
            C_Timer.After(30, function()
                -- This would use the actual cooldown in a real addon
                ccBreakersAvailable[key].available = true
                API.PrintDebug(breaker.name .. " off cooldown")
            end)
            
            return
        end
    end
}

-- Is CC effect
function PvPManager:IsCCEffect(spellID)
    -- This would check a comprehensive database of CC spells
    -- For implementation simplicity, we'll use a small set of examples
    
    local ccSpells = {
        -- Stuns
        [5211] = {category = "stun", name = "Mighty Bash"},
        [853] = {category = "stun", name = "Hammer of Justice"},
        [1833] = {category = "stun", name = "Cheap Shot"},
        
        -- Disorientation
        [2094] = {category = "disorient", name = "Blind"},
        [118] = {category = "disorient", name = "Polymorph"},
        [51514] = {category = "disorient", name = "Hex"},
        
        -- Silences
        [15487] = {category = "silence", name = "Silence"},
        [1330] = {category = "silence", name = "Garrote"},
        
        -- Incapacitates
        [6770] = {category = "incapacitate", name = "Sap"},
        [115078] = {category = "incapacitate", name = "Paralysis"},
        
        -- Fears
        [5246] = {category = "fear", name = "Intimidating Shout"},
        [5484] = {category = "fear", name = "Howl of Terror"},
        [8122] = {category = "fear", name = "Psychic Scream"},
        
        -- Roots
        [339] = {category = "root", name = "Entangling Roots"},
        [122] = {category = "root", name = "Frost Nova"},
        
        -- Knockbacks
        [6544] = {category = "knockback", name = "Heroic Leap"}
    }
    
    return ccSpells[spellID] ~= nil
end

-- Add CC to tracker
function PvPManager:AddCCToTracker(destGUID, destName, destFlags, spellID, spellName)
    -- Get CC details
    local ccDetails = self:GetCCDetails(spellID)
    
    if not ccDetails then
        return
    end
    
    -- Add to CC tracker
    if not ccTracker[destGUID] then
        ccTracker[destGUID] = {}
    end
    
    -- Check DR category
    local drCategory = ccDetails.category
    
    if not drCategory then
        return
    end
    
    local now = GetTime()
    
    -- Check for DR
    local drState = DR_STATE_FULL
    if drTracker[drCategory][destGUID] then
        local lastEnd = drTracker[drCategory][destGUID].endTime
        
        -- DR lasts for 18 seconds
        if now <= lastEnd + 18 then
            -- Progress DR state
            drState = drTracker[drCategory][destGUID].state + 1
            if drState > DR_STATE_IMMUNE then
                drState = DR_STATE_IMMUNE
            end
        else
            -- Reset DR
            drState = DR_STATE_FULL
        end
    end
    
    -- Calculate adjusted duration
    local baseDuration = ccDetails.duration or 6 -- Default to 6 seconds
    local adjustedDuration = baseDuration
    
    if drState == DR_STATE_HALF then
        adjustedDuration = baseDuration * 0.5
    elseif drState == DR_STATE_QUARTER then
        adjustedDuration = baseDuration * 0.25
    elseif drState == DR_STATE_IMMUNE then
        adjustedDuration = 0
    end
    
    -- Add to DR tracker
    drTracker[drCategory][destGUID] = {
        name = destName,
        guid = destGUID,
        state = drState,
        startTime = now,
        endTime = now + adjustedDuration
    }
    
    -- Add to CC tracker
    ccTracker[destGUID][spellID] = {
        name = spellName,
        spellID = spellID,
        category = drCategory,
        startTime = now,
        endTime = now + adjustedDuration,
        caster = UnitName("player") -- For simplification
    }
    
    API.PrintDebug(destName .. " affected by " .. spellName .. " for " .. adjustedDuration .. "s (DR state: " .. drState .. ")")
    
    -- If this is a friendly unit under CC, check if we should use a CC breaker
    if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
        self:CheckUseCCBreaker(destGUID, destName, spellID, adjustedDuration)
    end
    
    -- If burst after CC is enabled, check if we should burst
    local settings = ConfigRegistry:GetSettings("PvPManager")
    if settings.burstSettings.burstAfterCC and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
        -- This is an enemy that's been CC'd
        if not burstEnabled and drState == DR_STATE_FULL and adjustedDuration >= 4 then
            -- Only burst on full DR CCs that last at least 4 seconds
            self:ActivateBurst()
        end
    end
}

-- Remove CC from tracker
function PvPManager:RemoveCCFromTracker(destGUID, spellID)
    -- Remove from CC tracker
    if ccTracker[destGUID] and ccTracker[destGUID][spellID] then
        ccTracker[destGUID][spellID] = nil
    end
}

-- Check CC chains
function PvPManager:CheckCCChains(destGUID, spellID)
    -- This would check for optimal CC chains
    -- For implementation simplicity, we'll just print a debug message
    
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    if not settings.ccSettings.enableCCChains then
        return
    end
    
    -- Get CC details
    local ccDetails = self:GetCCDetails(spellID)
    
    if not ccDetails then
        return
    end
    
    local drCategory = ccDetails.category
    
    if not drCategory or not drTracker[drCategory] or not drTracker[drCategory][destGUID] then
        return
    end
    
    local drState = drTracker[drCategory][destGUID].state
    
    -- Only suggest chains on first application
    if drState == DR_STATE_FULL then
        -- This would check for follow-up CCs from team members
        API.PrintDebug("Suggest CC chain for " .. UnitName(self:GUIDToUnit(destGUID)) .. " using different DR category")
    end
}

-- Check use CC breaker
function PvPManager:CheckUseCCBreaker(destGUID, destName, spellID, duration)
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    if not settings.ccSettings.enableCCBreaking then
        return
    end
    
    -- Check if this is the player or a teammate
    local isPlayer = (destGUID == UnitGUID("player"))
    
    -- Get CC details
    local ccDetails = self:GetCCDetails(spellID)
    
    if not ccDetails then
        return
    end
    
    -- Decide if we should break this CC
    local shouldBreak = false
    
    -- Check CC category - break hard CC or long CC
    if ccDetails.category == "stun" or ccDetails.category == "incapacitate" or ccDetails.category == "fear" then
        shouldBreak = true
    elseif duration >= 4 then
        shouldBreak = true
    end
    
    -- Special cases
    if isPlayer and UnitHealth("player") / UnitHealthMax("player") < 0.4 then
        -- Player is at low health, break CC
        shouldBreak = true
    end
    
    if shouldBreak then
        -- Get available CC breaker
        local breaker = self:GetAvailableCCBreaker(destGUID)
        
        if breaker then
            API.PrintDebug("Suggest using " .. breaker.name .. " to break CC on " .. destName)
            
            -- In a real addon, we might cast the spell or suggest it to the player
        end
    end
}

-- Get available CC breaker
function PvPManager:GetAvailableCCBreaker(destGUID)
    -- Check if this is the player
    local isPlayer = (destGUID == UnitGUID("player"))
    
    -- Filter available breakers
    local availableBreakers = {}
    
    for key, breaker in pairs(ccBreakersAvailable) do
        if breaker.available then
            -- Check if this breaker can be used on this target
            if isPlayer then
                -- Self breakers
                if not breaker.targetOnly then
                    table.insert(availableBreakers, breaker)
                end
            else
                -- Target breakers (like Blessing of Protection)
                if breaker.targetOnly then
                    table.insert(availableBreakers, breaker)
                end
            end
        end
    end
    
    -- Sort by priority
    table.sort(availableBreakers, function(a, b)
        -- Sort by cooldown (use shorter cooldown first)
        return a.cooldown < b.cooldown
    end)
    
    -- Return highest priority breaker
    return availableBreakers[1]
end

-- Get CC details
function PvPManager:GetCCDetails(spellID)
    -- This would lookup CC details from a database
    -- For implementation simplicity, we'll use a small set of examples
    
    local ccSpells = {
        -- Stuns
        [5211] = {category = "stun", name = "Mighty Bash", duration = 5},
        [853] = {category = "stun", name = "Hammer of Justice", duration = 6},
        [1833] = {category = "stun", name = "Cheap Shot", duration = 4},
        
        -- Disorientation
        [2094] = {category = "disorient", name = "Blind", duration = 8},
        [118] = {category = "disorient", name = "Polymorph", duration = 8},
        [51514] = {category = "disorient", name = "Hex", duration = 8},
        
        -- Silences
        [15487] = {category = "silence", name = "Silence", duration = 4},
        [1330] = {category = "silence", name = "Garrote", duration = 3},
        
        -- Incapacitates
        [6770] = {category = "incapacitate", name = "Sap", duration = 8},
        [115078] = {category = "incapacitate", name = "Paralysis", duration = 4},
        
        -- Fears
        [5246] = {category = "fear", name = "Intimidating Shout", duration = 8},
        [5484] = {category = "fear", name = "Howl of Terror", duration = 4},
        [8122] = {category = "fear", name = "Psychic Scream", duration = 8},
        
        -- Roots
        [339] = {category = "root", name = "Entangling Roots", duration = 6},
        [122] = {category = "root", name = "Frost Nova", duration = 8},
        
        -- Knockbacks
        [6544] = {category = "knockback", name = "Heroic Leap", duration = 1}
    }
    
    return ccSpells[spellID]
}

-- Is arena unit
function PvPManager:IsArenaUnit(guid)
    -- Check arena units
    for unit, data in pairs(enemyArenaUnits) do
        if data.guid == guid then
            return true
        end
    end
    
    for unit, data in pairs(friendlyArenaUnits) do
        if data.guid == guid then
            return true
        end
    end
    
    return false
}

-- Update arena unit health
function PvPManager:UpdateArenaUnitHealth(guid)
    -- Find the unit
    for unit, data in pairs(enemyArenaUnits) do
        if data.guid == guid then
            -- Update health percentage
            local health = UnitHealth(unit)
            local maxHealth = UnitHealthMax(unit)
            
            if health and maxHealth and maxHealth > 0 then
                data.health = health / maxHealth * 100
            end
            
            return
        end
    end
    
    for unit, data in pairs(friendlyArenaUnits) do
        if data.guid == guid then
            -- Update health percentage
            local health = UnitHealth(unit)
            local maxHealth = UnitHealthMax(unit)
            
            if health and maxHealth and maxHealth > 0 then
                data.health = health / maxHealth * 100
            end
            
            return
        end
    end
}

-- GUID to unit
function PvPManager:GUIDToUnit(guid)
    -- Check player
    if UnitGUID("player") == guid then
        return "player"
    end
    
    -- Check target
    if UnitGUID("target") == guid then
        return "target"
    end
    
    -- Check focus
    if UnitGUID("focus") == guid then
        return "focus"
    end
    
    -- Check arena units
    for i = 1, 5 do
        local unit = "arena" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    -- Check party units
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    -- Not found
    return nil
}

-- On arena opponent specs ready
function PvPManager:OnArenaOpponentSpecsReady()
    -- Get opponent specs
    for i = 1, 5 do
        local unit = "arena" .. i
        
        if UnitExists(unit) then
            -- Get unit details
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            local class = select(2, UnitClass(unit))
            local specID = GetArenaOpponentSpec(i)
            local specName = specID and select(2, GetSpecializationInfoByID(specID)) or "Unknown"
            
            -- Store opponent info
            enemyArenaUnits[unit] = {
                guid = guid,
                name = name,
                class = class,
                spec = specID,
                health = 100,
                isHealer = self:IsHealerSpec(specID),
                isDPS = not self:IsHealerSpec(specID),
                isTank = self:IsTankSpec(specID)
            }
            
            API.PrintDebug("Arena opponent " .. i .. ": " .. name .. " - " .. (class or "Unknown") .. " " .. specName)
            
            -- Store class for quick lookup
            enemyClasses[guid] = class
            
            -- Store specialization
            enemySpecializations[guid] = {
                name = name,
                class = class,
                spec = specID,
                isHealer = self:IsHealerSpec(specID)
            }
        end
    end
    
    -- Analyze arena composition
    self:AnalyzeArenaComposition()
}

-- On arena opponent update
function PvPManager:OnArenaOpponentUpdate(unit, updateReason)
    -- Update arena unit info
    if string.find(unit, "arena") then
        local i = tonumber(string.sub(unit, 6))
        
        if UnitExists(unit) then
            -- Get unit details
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            local class = select(2, UnitClass(unit))
            local specID = GetArenaOpponentSpec(i)
            
            -- Store opponent info
            enemyArenaUnits[unit].guid = guid
            enemyArenaUnits[unit].name = name
            enemyArenaUnits[unit].class = class
            enemyArenaUnits[unit].spec = specID
            enemyArenaUnits[unit].health = UnitHealth(unit) / UnitHealthMax(unit) * 100
            enemyArenaUnits[unit].isHealer = self:IsHealerSpec(specID)
            enemyArenaUnits[unit].isDPS = not self:IsHealerSpec(specID)
            enemyArenaUnits[unit].isTank = self:IsTankSpec(specID)
            
            -- Store class for quick lookup
            enemyClasses[guid] = class
        end
    end
}

-- On enter battleground
function PvPManager:OnEnterBattleground()
    -- Update PvP state
    self:UpdatePvPState()
    
    -- Check if this is a rated battleground
    if C_PvP.IsRatedBattleground() then
        API.PrintDebug("Entered rated battleground")
        inRatedMatch = true
        currentBracket = "RBG"
    else
        API.PrintDebug("Entered battleground")
        inRatedMatch = false
        currentBracket = "BG"
    end
}

-- On unit aura changed
function PvPManager:OnUnitAuraChanged(unit)
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- Check for CC effects
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellID = UnitDebuff(unit, i)
        
        if name and self:IsCCEffect(spellID) then
            local guid = UnitGUID(unit)
            local unitName = UnitName(unit)
            
            -- Process CC for DR tracking
            local ccDetails = self:GetCCDetails(spellID)
            
            if ccDetails and ccDetails.category then
                -- Update DR tracking
                local now = GetTime()
                local endTime = expirationTime or (now + duration)
                
                -- Add to DR tracker if not already there
                if not drTracker[ccDetails.category][guid] then
                    drTracker[ccDetails.category][guid] = {
                        name = unitName,
                        guid = guid,
                        state = DR_STATE_FULL,
                        startTime = now,
                        endTime = endTime
                    }
                end
            end
            
            -- Add to CC tracker if not already there
            if not ccTracker[guid] then
                ccTracker[guid] = {}
            end
            
            if not ccTracker[guid][spellID] then
                ccTracker[guid][spellID] = {
                    name = name,
                    spellID = spellID,
                    category = ccDetails and ccDetails.category or "unknown",
                    startTime = GetTime(),
                    endTime = expirationTime or (GetTime() + duration),
                    caster = unitCaster and UnitName(unitCaster) or "Unknown"
                }
            end
        end
    end
}

-- On unit spellcast succeeded
function PvPManager:OnUnitSpellcastSucceeded(unit, spellID)
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- Record important spells
    if unit == "player" then
        -- Check for burst activation spells
        if spellID == ConfigRegistry:GetSettings("PvPManager").burstSettings.burstModeKey then
            self:ActivateBurst()
        end
    end
}

-- On PvP talent update
function PvPManager:OnPvPTalentUpdate()
    -- Update PvP talents
    self:UpdatePvPTalents()
    
    -- Might need to adjust rotation based on talents
    self:AdjustPvPRotation()
}

-- On PvP match active
function PvPManager:OnPvPMatchActive()
    -- Set rated match flag
    inRatedMatch = true
    
    -- Determine bracket
    if inArena then
        currentBracket = arenaTeamSize .. "v" .. arenaTeamSize
    else
        currentBracket = "RBG"
    end
    
    API.PrintDebug("PvP match active: " .. currentBracket)
}

-- On PvP match complete
function PvPManager:OnPvPMatchComplete()
    -- Reset rated match flag
    inRatedMatch = false
    
    -- Reset bracket
    currentBracket = nil
    
    API.PrintDebug("PvP match complete")
}

-- Analyze arena composition
function PvPManager:AnalyzeArenaComposition()
    -- Count healers, ranged, melee
    local healerCount = 0
    local rangedCount = 0
    local meleeCount = 0
    
    for unit, data in pairs(enemyArenaUnits) do
        if data.isHealer then
            healerCount = healerCount + 1
        elseif data.class == "MAGE" or data.class == "WARLOCK" or data.class == "PRIEST" or 
               data.class == "HUNTER" or (data.class == "DRUID" and data.spec == 1) or
               (data.class == "SHAMAN" and data.spec == 1) or data.class == "EVOKER" then
            rangedCount = rangedCount + 1
        else
            meleeCount = meleeCount + 1
        end
    end
    
    -- Identify common compositions
    local comp = ""
    
    if healerCount == 1 and meleeCount == 1 and rangedCount == 0 and arenaTeamSize == 2 then
        comp = "Healer+Melee"
    elseif healerCount == 1 and meleeCount == 0 and rangedCount == 1 and arenaTeamSize == 2 then
        comp = "Healer+Ranged"
    elseif healerCount == 0 and meleeCount == 2 and rangedCount == 0 and arenaTeamSize == 2 then
        comp = "Double Melee"
    elseif healerCount == 0 and meleeCount == 0 and rangedCount == 2 and arenaTeamSize == 2 then
        comp = "Double Ranged"
    elseif healerCount == 0 and meleeCount == 1 and rangedCount == 1 and arenaTeamSize == 2 then
        comp = "Melee+Ranged"
    elseif healerCount == 1 and meleeCount == 2 and rangedCount == 0 and arenaTeamSize == 3 then
        comp = "Healer+Double Melee"
    elseif healerCount == 1 and meleeCount == 0 and rangedCount == 2 and arenaTeamSize == 3 then
        comp = "Healer+Double Ranged"
    elseif healerCount == 1 and meleeCount == 1 and rangedCount == 1 and arenaTeamSize == 3 then
        comp = "Healer+Melee+Ranged"
    end
    
    -- Check for specific comps
    local classComps = {}
    for unit, data in pairs(enemyArenaUnits) do
        if data.class then
            table.insert(classComps, data.class)
        end
    end
    
    -- Sort for consistent comp names
    table.sort(classComps)
    
    -- Check for RMP (Rogue, Mage, Priest)
    if #classComps == 3 and classComps[1] == "MAGE" and classComps[2] == "PRIEST" and classComps[3] == "ROGUE" then
        comp = "RMP"
    end
    
    -- Store enemy comp
    enemyComposition = {
        healerCount = healerCount,
        rangedCount = rangedCount,
        meleeCount = meleeCount,
        composition = comp
    }
    
    API.PrintDebug("Enemy composition: " .. comp .. " (Healers: " .. healerCount .. ", Ranged: " .. rangedCount .. ", Melee: " .. meleeCount .. ")")
    
    -- Adjust rotation based on composition
    self:AdjustPvPRotationForComp()
}

-- Adjust PvP rotation
function PvPManager:AdjustPvPRotation()
    -- This would adjust the rotation based on PvP talents and other factors
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("Adjusting PvP rotation based on talents")
}

-- Adjust PvP rotation for composition
function PvPManager:AdjustPvPRotationForComp()
    -- This would adjust the rotation based on the enemy composition
    -- For implementation simplicity, we'll just print a debug message
    
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    if not settings.arenaBehavior.adaptToEnemyComp then
        return
    end
    
    API.PrintDebug("Adjusting PvP rotation for comp: " .. enemyComposition.composition)
    
    -- Different strategies for different compositions
    if enemyComposition.composition == "RMP" then
        -- Special handling for RMP (one of the most dangerous comps)
        API.PrintDebug("RMP detected: Playing defensively")
    elseif enemyComposition.healerCount > 0 and settings.arenaBehavior.adaptToEnemyHealer then
        -- If there's a healer, prioritize them
        API.PrintDebug("Enemy healer detected: Prioritizing healer")
    elseif enemyComposition.composition == "Double Melee" then
        -- Against double melee, we might want more defensive abilities
        API.PrintDebug("Double melee detected: Enhancing defensive priority")
    end
}

-- Activate burst
function PvPManager:ActivateBurst()
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    if not settings.burstSettings.enableBurstMode then
        return
    end
    
    -- Start burst mode
    burstEnabled = true
    burstStart = GetTime()
    burstDuration = settings.burstSettings.burstDuration
    
    API.PrintDebug("Burst mode activated for " .. burstDuration .. " seconds")
    
    -- Schedule burst end
    C_Timer.After(burstDuration, function()
        burstEnabled = false
        API.PrintDebug("Burst mode ended")
    end)
}

-- Is in burst mode
function PvPManager:IsInBurstMode()
    return burstEnabled
}

-- Get burst time remaining
function PvPManager:GetBurstTimeRemaining()
    if not burstEnabled then
        return 0
    end
    
    local now = GetTime()
    local remaining = (burstStart + burstDuration) - now
    
    if remaining < 0 then
        burstEnabled = false
        return 0
    end
    
    return remaining
}

-- Get time until DR reset
function PvPManager:GetTimeUntilDRReset(unit, category)
    local guid = UnitGUID(unit)
    
    if not guid or not category or not drTracker[category] or not drTracker[category][guid] then
        return 0
    end
    
    local now = GetTime()
    local drEndTime = drTracker[category][guid].endTime
    
    -- DR lasts for 18 seconds after CC ends
    local resetTime = drEndTime + 18
    local remaining = resetTime - now
    
    if remaining < 0 then
        return 0
    end
    
    return remaining
}

-- Get DR state
function PvPManager:GetDRState(unit, category)
    local guid = UnitGUID(unit)
    
    if not guid or not category or not drTracker[category] or not drTracker[category][guid] then
        return DR_STATE_FULL
    end
    
    local now = GetTime()
    local drEndTime = drTracker[category][guid].endTime
    
    -- Check if DR has reset (18 seconds after CC ends)
    if now > drEndTime + 18 then
        return DR_STATE_FULL
    end
    
    return drTracker[category][guid].state
}

-- Get current PvP rotation
function PvPManager:GetCurrentPvPRotation()
    return activePvPRotation
}

-- Is healer spec
function PvPManager:IsHealerSpec(specID)
    -- Check healer specs
    local healerSpecs = {
        [105] = true, -- Restoration Druid
        [270] = true, -- Mistweaver Monk
        [65] = true,  -- Holy Paladin
        [256] = true, -- Discipline Priest
        [257] = true, -- Holy Priest
        [264] = true, -- Restoration Shaman
        [1468] = true -- Preservation Evoker
    }
    
    return healerSpecs[specID] or false
}

-- Is tank spec
function PvPManager:IsTankSpec(specID)
    -- Check tank specs
    local tankSpecs = {
        [250] = true, -- Blood Death Knight
        [104] = true, -- Guardian Druid
        [268] = true, -- Brewmaster Monk
        [66] = true,  -- Protection Paladin
        [73] = true,  -- Protection Warrior
        [581] = true  -- Vengeance Demon Hunter
    }
    
    return tankSpecs[specID] or false
}

-- Is in PvP
function PvPManager:IsInPvP()
    return inPvP
}

-- Is in arena
function PvPManager:IsInArena()
    return inArena
}

-- Is in battleground
function PvPManager:IsInBattleground()
    return inBattleground
}

-- Get arena team size
function PvPManager:GetArenaTeamSize()
    return arenaTeamSize
}

-- Should use PvP rotation
function PvPManager:ShouldUsePvPRotation()
    local settings = ConfigRegistry:GetSettings("PvPManager")
    return inPvP and settings.generalSettings.enablePvPMode
}

-- Is enemy healer present
function PvPManager:IsEnemyHealerPresent()
    for _, data in pairs(enemyArenaUnits) do
        if data.isHealer then
            return true
        end
    end
    
    return false
}

-- Get enemy healer unit
function PvPManager:GetEnemyHealerUnit()
    for unit, data in pairs(enemyArenaUnits) do
        if data.isHealer then
            return unit
        end
    end
    
    return nil
}

-- Should use defensive playstyle
function PvPManager:ShouldUseDefensivePlaystyle()
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    -- Check defensive mode setting
    if settings.defensiveSettings.defensiveMode == "Conservative" then
        return true
    elseif settings.defensiveSettings.defensiveMode == "Aggressive" then
        return false
    elseif settings.defensiveSettings.defensiveMode == "Auto-Adapt" then
        -- Auto-adapt based on health, enemy comp, etc.
        local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100
        
        if playerHealth < settings.defensiveSettings.defensiveThreshold then
            return true
        end
        
        -- Check enemy cooldowns
        for guid, data in pairs(enemySpecializations) do
            if data.cooldowns then
                for spellID, cdInfo in pairs(data.cooldowns) do
                    if cdInfo.importance == "high" and GetTime() < cdInfo.endTime then
                        -- Enemy has a high-importance cooldown active
                        return true
                    end
                end
            end
        end
        
        -- Check enemy comp
        if enemyComposition.composition == "RMP" or enemyComposition.composition == "Double Melee" then
            -- These comps are dangerous, be more defensive
            return true
        end
    end
    
    return false
}

-- Should prioritize target based on PvP rules
function PvPManager:ShouldPrioritizeTarget(unit)
    if not unit then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    -- Check if unit is a healer
    local guid = UnitGUID(unit)
    
    if guid and enemySpecializations[guid] and enemySpecializations[guid].isHealer and settings.arenaBehavior.adaptToEnemyHealer then
        -- Prioritize healers
        return true
    end
    
    -- Check if unit is under CC
    if settings.ccSettings.prioritizeCCTarget and self:IsUnitControlled(unit) then
        return true
    end
    
    return false
}

-- Is unit controlled
function PvPManager:IsUnitControlled(unit)
    if not unit then
        return false
    end
    
    local guid = UnitGUID(unit)
    
    if not guid or not ccTracker[guid] then
        return false
    end
    
    local now = GetTime()
    
    for spellID, data in pairs(ccTracker[guid]) do
        if now < data.endTime then
            return true
        end
    end
    
    return false
}

-- Get PvP ability priority modifier
function PvPManager:GetPvPAbilityPriorityModifier(spellID)
    -- This would return a priority modifier for abilities in PvP
    -- For implementation simplicity, we'll return 0 (no modification)
    
    -- Specific ability modifications for PvP
    local abilityModifiers = {
        -- CC abilities get higher priority in PvP
        [5211] = 2,  -- Mighty Bash
        [853] = 2,   -- Hammer of Justice
        [1833] = 2,  -- Cheap Shot
        [2094] = 2,  -- Blind
        [118] = 2,   -- Polymorph
        [51514] = 2, -- Hex
        
        -- Defensive abilities get higher priority in PvP
        [45438] = 3, -- Ice Block
        [642] = 3,   -- Divine Shield
        [31224] = 3, -- Cloak of Shadows
        [5277] = 3,  -- Evasion
        
        -- Burst abilities get higher priority during burst phase
        [12472] = 3, -- Icy Veins (if burst)
        [190319] = 3, -- Combustion (if burst)
        [1719] = 3,   -- Recklessness (if burst)
        
        -- Interrupt abilities get higher priority in PvP
        [2139] = 2,  -- Counterspell
        [6552] = 2,  -- Pummel
        [1766] = 2,  -- Kick
        [47528] = 2, -- Mind Freeze
        [57994] = 2, -- Wind Shear
    }
    
    local modifier = abilityModifiers[spellID] or 0
    
    -- If we're in burst mode, boost burst abilities more
    if burstEnabled and (spellID == 12472 or spellID == 190319 or spellID == 1719) then
        modifier = modifier + 2
    end
    
    return modifier
}

-- Open PvP Template Editor
function PvPManager:OpenPvPTemplateEditor()
    -- This would open a UI to edit PvP templates
    -- For implementation simplicity, we'll just print a debug message
    API.PrintDebug("PvP Template Editor would open here")
}

-- Return the module
return PvPManager