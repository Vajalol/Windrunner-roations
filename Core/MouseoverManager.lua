------------------------------------------
-- WindrunnerRotations - Mouseover Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local MouseoverManager = {}
WR.MouseoverManager = MouseoverManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Data storage
local mouseoverUnits = {}
local mouseoverEnabled = false
local mouseoverPreferredTarget = nil
local mouseoverTargetOfTarget = nil
local mouseoverLastGUID = nil
local mouseoverLastTime = 0
local MOUSEOVER_MAX_AGE = 2.5  -- How long to remember a mouseover target (seconds)
local unitPriorities = {}
local CATEGORY_FRIENDLY = "friendly"
local CATEGORY_HOSTILE = "hostile"
local mouseoverSpells = {}
local targetOfMouseoverSpells = {}
local mouseoverGUID = nil
local currentMouseoverUnit = nil
local inCombat = false
local friendlyUnits = {}
local hostileUnits = {}
local specialUnits = {}
local smartTargetCache = {}

-- Initialize the Mouseover Manager
function MouseoverManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize mouseover data
    self:InitializeMouseoverData()
    
    API.PrintDebug("Mouseover Manager initialized")
    return true
end

-- Register settings
function MouseoverManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("MouseoverManager", {
        generalSettings = {
            enableMouseoverCasting = {
                displayName = "Enable Mouseover Casting",
                description = "Allow casting spells on mouseover targets",
                type = "toggle",
                default = true
            },
            targetPriorityMode = {
                displayName = "Target Priority Mode",
                description = "How to prioritize mouseover targets vs. current target",
                type = "dropdown",
                options = {"Mouseover First", "Target First", "Smart Priority", "Friendly/Hostile Split"},
                default = "Smart Priority"
            },
            mouseoverDefaultRange = {
                displayName = "Mouseover Default Range",
                description = "Default range to consider for mouseover targets (yards)",
                type = "slider",
                min = 5,
                max = 100,
                step = 5,
                default = 40
            },
            rememberMouseoverTarget = {
                displayName = "Remember Mouseover Target",
                description = "Remember last mouseover target for a period of time",
                type = "toggle",
                default = true
            },
            mouseoverMaxAge = {
                displayName = "Mouseover Memory Duration",
                description = "How long to remember a mouseover target (seconds)",
                type = "slider",
                min = 1,
                max = 10,
                step = 0.5,
                default = 2.5
            }
        },
        friendlySettings = {
            enableFriendlyMouseover = {
                displayName = "Enable Friendly Mouseover",
                description = "Enable mouseover casting on friendly targets",
                type = "toggle",
                default = true
            },
            friendlyTargetPriority = {
                displayName = "Friendly Target Priority",
                description = "Priority for friendly mouseover targets",
                type = "dropdown",
                options = {"Low Health First", "Class Priority", "Role Priority", "Distance Priority"},
                default = "Low Health First"
            },
            prioritizeTank = {
                displayName = "Prioritize Tanks",
                description = "Higher priority for tanks in friendly targeting",
                type = "toggle",
                default = true
            },
            prioritizeInCombat = {
                displayName = "Prioritize In-Combat Units",
                description = "Higher priority for friendly units in combat",
                type = "toggle",
                default = true
            },
            enableMouseoverHealing = {
                displayName = "Enable Mouseover Healing",
                description = "Allow healing spells on mouseover targets",
                type = "toggle",
                default = true
            }
        },
        hostileSettings = {
            enableHostileMouseover = {
                displayName = "Enable Hostile Mouseover",
                description = "Enable mouseover casting on hostile targets",
                type = "toggle",
                default = true
            },
            hostileTargetPriority = {
                displayName = "Hostile Target Priority",
                description = "Priority for hostile mouseover targets",
                type = "dropdown",
                options = {"Low Health First", "Class Priority", "Casting Priority", "Distance Priority"},
                default = "Casting Priority"
            },
            prioritizeCasters = {
                displayName = "Prioritize Casters",
                description = "Higher priority for enemy casters",
                type = "toggle",
                default = true
            },
            prioritizeImportantNPCs = {
                displayName = "Prioritize Important NPCs",
                description = "Higher priority for important or rare enemy NPCs",
                type = "toggle",
                default = true
            },
            enableMouseoverDamage = {
                displayName = "Enable Mouseover Damage",
                description = "Allow damage spells on mouseover targets",
                type = "toggle",
                default = true
            }
        },
        advancedSettings = {
            enableTargetOfMouseover = {
                displayName = "Enable Target of Mouseover",
                description = "Allow casting spells on mouseover target's target",
                type = "toggle",
                default = true
            },
            checkLineOfSight = {
                displayName = "Check Line of Sight",
                description = "Check if mouseover target is in line of sight",
                type = "toggle",
                default = true
            },
            smartTargetSwitching = {
                displayName = "Smart Target Switching",
                description = "Intelligently switch targets based on mouseover",
                type = "toggle",
                default = true
            },
            mouseoverMacroConversion = {
                displayName = "Mouseover Macro Conversion",
                description = "Convert standard abilities to mouseover abilities",
                type = "toggle",
                default = true
            },
            returnToMainTarget = {
                displayName = "Return to Main Target",
                description = "Return focus to main target after mouseover cast",
                type = "toggle",
                default = true
            },
            showMouseoverTooltips = {
                displayName = "Show Mouseover Tooltips",
                description = "Show additional spell tooltips for mouseover functionality",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Register for events
function MouseoverManager:RegisterEvents()
    -- Register for mouseover events
    API.RegisterEvent("UPDATE_MOUSEOVER_UNIT", function()
        self:OnUpdateMouseoverUnit()
    end)
    
    -- Register for combat events
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnCombatStart()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnCombatEnd()
    end)
    
    -- Register for unit events
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        self:OnUnitHealthChanged(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit)
        self:OnUnitSpellcastStart(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_STOP", function(unit)
        self:OnUnitSpellcastStop(unit)
    end)
    
    -- Register for player events
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:OnPlayerTargetChanged()
    end)
    
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:OnPlayerFocusChanged()
    end)
    
    -- Register for group events
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:OnGroupRosterUpdate()
    end)
    
    -- Register for unit storage update
    C_Timer.NewTicker(0.1, function()
        self:UpdateUnitStorage()
    end)
}

-- Initialize mouseover data
function MouseoverManager:InitializeMouseoverData()
    -- Set up unit priorities
    unitPriorities = {
        [CATEGORY_FRIENDLY] = {
            ["TANK"] = 90,
            ["HEALER"] = 80,
            ["DPS"] = 70,
            ["PET"] = 60,
            ["NPC"] = 50
        },
        [CATEGORY_HOSTILE] = {
            ["HEALER"] = 90,
            ["CASTER"] = 85,
            ["PLAYER"] = 80,
            ["ELITE"] = 70,
            ["NORMAL"] = 60,
            ["PET"] = 50
        }
    }
    
    -- Set up spells that work with mouseover
    mouseoverSpells = {
        -- Healing spells
        healingSpells = {
            -- Priest
            [2061] = true,    -- Flash Heal
            [2060] = true,    -- Greater Heal
            [139] = true,     -- Renew
            [17] = true,      -- Power Word: Shield
            [33076] = true,   -- Prayer of Mending
            
            -- Druid
            [8936] = true,    -- Regrowth
            [774] = true,     -- Rejuvenation
            [33763] = true,   -- Lifebloom
            [48438] = true,   -- Wild Growth
            
            -- Paladin
            [19750] = true,   -- Flash of Light
            [82326] = true,   -- Holy Light
            [53563] = true,   -- Beacon of Light
            
            -- Shaman
            [8004] = true,    -- Healing Surge
            [1064] = true,    -- Chain Heal
            [61295] = true,   -- Riptide
            
            -- Monk
            [116670] = true,  -- Vivify
            [115175] = true,  -- Soothing Mist
            [124682] = true,  -- Enveloping Mist
            
            -- Evoker
            [367230] = true,  -- Reversion
            [355936] = true,  -- Dream Breath
            [364343] = true,  -- Echo
            
            -- Universal
            [301930] = true,  -- Healthstone
            [6262] = true,    -- Healthstone (item)
        },
        
        -- Damage spells (a subset that work well with mouseover)
        damageSpells = {
            -- Priest
            [589] = true,     -- Shadow Word: Pain
            [34914] = true,   -- Vampiric Touch
            
            -- Warlock
            [172] = true,     -- Corruption
            [980] = true,     -- Agony
            [603] = true,     -- Doom
            [30108] = true,   -- Unstable Affliction
            
            -- Druid
            [8921] = true,    -- Moonfire
            [93402] = true,   -- Sunfire
            
            -- Mage
            [116] = true,     -- Frostbolt
            [133] = true,     -- Fireball
            [44425] = true,   -- Arcane Barrage
            
            -- Shaman
            [188389] = true,  -- Flame Shock
            [51505] = true,   -- Lava Burst
            
            -- Death Knight
            [55095] = true,   -- Frost Fever
            [55078] = true,   -- Blood Plague
            
            -- Hunter
            [1978] = true,    -- Serpent Sting
            
            -- Others are typically better with direct target
        },
        
        -- Utility spells
        utilitySpells = {
            -- Universal
            [20484] = true,   -- Rebirth (Druid)
            [2006] = true,    -- Resurrection (Priest)
            [7328] = true,    -- Redemption (Paladin)
            [2008] = true,    -- Ancestral Spirit (Shaman)
            [115178] = true,  -- Resuscitate (Monk)
            [50769] = true,   -- Revive (Druid)
            [982] = true,     -- Revive Pet (Hunter)
            
            -- Buffs
            [21562] = true,   -- Power Word: Fortitude
            [1459] = true,    -- Arcane Intellect
            [6673] = true,    -- Battle Shout
            
            -- Dispels
            [528] = true,     -- Dispel Magic
            [527] = true,     -- Purify
            [4987] = true,    -- Cleanse
            [2782] = true,    -- Remove Corruption
            [115450] = true,  -- Detox
            [51886] = true,   -- Cleanse Spirit
            
            -- CC
            [118] = true,     -- Polymorph
            [51514] = true,   -- Hex
            [20066] = true,   -- Repentance
            [605] = true,     -- Mind Control
            [2637] = true,    -- Hibernate
            
            -- Interrupts
            [2139] = true,    -- Counterspell
            [57994] = true,   -- Wind Shear
            [147362] = true,  -- Counter Shot
            [96231] = true,   -- Rebuke
            [6552] = true,    -- Pummel
            [1766] = true,    -- Kick
            [47528] = true,   -- Mind Freeze
        }
    }
    
    -- Set up spells that work with target of mouseover
    targetOfMouseoverSpells = {
        -- Generally control or utility spells
        [355] = true,         -- Taunt
        [62124] = true,       -- Hand of Reckoning
        [56222] = true,       -- Dark Command
        [6795] = true,        -- Growl
        [5484] = true,        -- Howl of Terror
        [8122] = true,        -- Psychic Scream
        [198898] = true,      -- Song of Chi-Ji
    }
    
    -- Initialize smart target cache
    smartTargetCache = {
        lastTarget = nil,
        lastMouseover = nil,
        lastDecision = nil,
        lastDecisionTime = 0
    }
}

-- Update unit storage
function MouseoverManager:UpdateUnitStorage()
    -- Clear storage
    friendlyUnits = {}
    hostileUnits = {}
    specialUnits = {}
    
    -- Add player to friendly units
    friendlyUnits["player"] = {
        guid = UnitGUID("player"),
        name = UnitName("player"),
        isPlayer = true,
        isTank = false,
        isHealer = false,
        health = UnitHealth("player") / UnitHealthMax("player") * 100,
        distance = 0,
        inCombat = inCombat,
        priority = 70
    }
    
    -- Add current target
    if UnitExists("target") then
        if UnitCanAttack("player", "target") then
            hostileUnits["target"] = {
                guid = UnitGUID("target"),
                name = UnitName("target"),
                isPlayer = UnitIsPlayer("target"),
                isCaster = self:IsUnitCaster("target"),
                health = UnitHealth("target") / UnitHealthMax("target") * 100,
                distance = 5, -- Placeholder, would be calculated in a real addon
                important = self:IsImportantNPC("target"),
                priority = 80 -- Current target gets high priority
            }
        else
            friendlyUnits["target"] = {
                guid = UnitGUID("target"),
                name = UnitName("target"),
                isPlayer = UnitIsPlayer("target"),
                isTank = self:IsUnitTank("target"),
                isHealer = self:IsUnitHealer("target"),
                health = UnitHealth("target") / UnitHealthMax("target") * 100,
                distance = 5, -- Placeholder, would be calculated in a real addon
                inCombat = UnitAffectingCombat("target"),
                priority = 75 -- Current target gets high priority
            }
        end
    end
    
    -- Add focus
    if UnitExists("focus") then
        if UnitCanAttack("player", "focus") then
            hostileUnits["focus"] = {
                guid = UnitGUID("focus"),
                name = UnitName("focus"),
                isPlayer = UnitIsPlayer("focus"),
                isCaster = self:IsUnitCaster("focus"),
                health = UnitHealth("focus") / UnitHealthMax("focus") * 100,
                distance = 10, -- Placeholder, would be calculated in a real addon
                important = self:IsImportantNPC("focus"),
                priority = 85 -- Focus gets very high priority
            }
        else
            friendlyUnits["focus"] = {
                guid = UnitGUID("focus"),
                name = UnitName("focus"),
                isPlayer = UnitIsPlayer("focus"),
                isTank = self:IsUnitTank("focus"),
                isHealer = self:IsUnitHealer("focus"),
                health = UnitHealth("focus") / UnitHealthMax("focus") * 100,
                distance = 10, -- Placeholder, would be calculated in a real addon
                inCombat = UnitAffectingCombat("focus"),
                priority = 85 -- Focus gets very high priority
            }
        end
    end
    
    -- Add mouseover
    if UnitExists("mouseover") then
        if UnitCanAttack("player", "mouseover") then
            hostileUnits["mouseover"] = {
                guid = UnitGUID("mouseover"),
                name = UnitName("mouseover"),
                isPlayer = UnitIsPlayer("mouseover"),
                isCaster = self:IsUnitCaster("mouseover"),
                health = UnitHealth("mouseover") / UnitHealthMax("mouseover") * 100,
                distance = 10, -- Placeholder, would be calculated in a real addon
                important = self:IsImportantNPC("mouseover"),
                priority = 90 -- Mouseover gets highest priority
            }
        else
            friendlyUnits["mouseover"] = {
                guid = UnitGUID("mouseover"),
                name = UnitName("mouseover"),
                isPlayer = UnitIsPlayer("mouseover"),
                isTank = self:IsUnitTank("mouseover"),
                isHealer = self:IsUnitHealer("mouseover"),
                health = UnitHealth("mouseover") / UnitHealthMax("mouseover") * 100,
                distance = 10, -- Placeholder, would be calculated in a real addon
                inCombat = UnitAffectingCombat("mouseover"),
                priority = 90 -- Mouseover gets highest priority
            }
        end
    end
    
    -- Add party/raid members to friendly units
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                friendlyUnits[unit] = {
                    guid = UnitGUID(unit),
                    name = UnitName(unit),
                    isPlayer = true,
                    isTank = self:IsUnitTank(unit),
                    isHealer = self:IsUnitHealer(unit),
                    health = UnitHealth(unit) / UnitHealthMax(unit) * 100,
                    distance = 15, -- Placeholder, would be calculated in a real addon
                    inCombat = UnitAffectingCombat(unit),
                    priority = 70
                }
                
                -- Adjust priority based on role and health
                if friendlyUnits[unit].isTank then
                    friendlyUnits[unit].priority = 80
                elseif friendlyUnits[unit].isHealer then
                    friendlyUnits[unit].priority = 75
                end
                
                -- Lower health gets higher priority
                if friendlyUnits[unit].health < 50 then
                    friendlyUnits[unit].priority = friendlyUnits[unit].priority + (50 - friendlyUnits[unit].health) / 5
                end
            end
        end
    end
    
    -- Add nameplate units to hostile units
    for i = 1, 40 do
        local unit = "nameplate" .. i
        
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            hostileUnits[unit] = {
                guid = UnitGUID(unit),
                name = UnitName(unit),
                isPlayer = UnitIsPlayer(unit),
                isCaster = self:IsUnitCaster(unit),
                health = UnitHealth(unit) / UnitHealthMax(unit) * 100,
                distance = 20, -- Placeholder, would be calculated in a real addon
                important = self:IsImportantNPC(unit),
                priority = 60
            }
            
            -- Adjust priority based on type
            if hostileUnits[unit].isPlayer then
                hostileUnits[unit].priority = 80
            elseif hostileUnits[unit].isCaster then
                hostileUnits[unit].priority = 85
            elseif hostileUnits[unit].important then
                hostileUnits[unit].priority = 90
            end
            
            -- Lower health gets higher priority
            if hostileUnits[unit].health < 20 then
                hostileUnits[unit].priority = hostileUnits[unit].priority + (20 - hostileUnits[unit].health) / 2
            end
        end
    end
    
    -- Store special units
    specialUnits = {
        player = friendlyUnits["player"],
        target = UnitExists("target") and (friendlyUnits["target"] or hostileUnits["target"]) or nil,
        focus = UnitExists("focus") and (friendlyUnits["focus"] or hostileUnits["focus"]) or nil,
        mouseover = UnitExists("mouseover") and (friendlyUnits["mouseover"] or hostileUnits["mouseover"]) or nil
    }
}

-- On update mouseover unit
function MouseoverManager:OnUpdateMouseoverUnit()
    -- Get settings
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if mouseover casting is disabled
    if not settings.generalSettings.enableMouseoverCasting then
        return
    end
    
    -- Get mouseover info
    if UnitExists("mouseover") then
        local guid = UnitGUID("mouseover")
        local hostile = UnitCanAttack("player", "mouseover")
        
        -- Skip if hostile mouseover is disabled and this is a hostile unit
        if hostile and not settings.hostileSettings.enableHostileMouseover then
            return
        end
        
        -- Skip if friendly mouseover is disabled and this is a friendly unit
        if not hostile and not settings.friendlySettings.enableFriendlyMouseover then
            return
        end
        
        -- Store mouseover info
        mouseoverGUID = guid
        currentMouseoverUnit = "mouseover"
        mouseoverLastGUID = guid
        mouseoverLastTime = GetTime()
        mouseoverEnabled = true
        
        -- Store in mouseover units
        mouseoverUnits[guid] = {
            unit = "mouseover",
            guid = guid,
            name = UnitName("mouseover"),
            hostile = hostile,
            lastSeen = GetTime(),
            priority = hostile and self:CalculateHostilePriority("mouseover") or self:CalculateFriendlyPriority("mouseover")
        }
        
        -- Store target of mouseover
        if settings.advancedSettings.enableTargetOfMouseover and UnitExists("mouseovertarget") then
            mouseoverTargetOfTarget = {
                guid = UnitGUID("mouseovertarget"),
                name = UnitName("mouseovertarget"),
                unit = "mouseovertarget",
                hostile = UnitCanAttack("player", "mouseovertarget"),
                lastSeen = GetTime()
            }
        else
            mouseoverTargetOfTarget = nil
        end
        
        -- Update preferred target
        self:UpdatePreferredTarget()
    else
        -- Clear current mouseover
        currentMouseoverUnit = nil
        mouseoverGUID = nil
        
        -- Check if we should remember the last mouseover
        if settings.generalSettings.rememberMouseoverTarget and mouseoverLastGUID and (GetTime() - mouseoverLastTime) < settings.generalSettings.mouseoverMaxAge then
            -- Keep using the last mouseover if it's recent enough
            mouseoverEnabled = true
        else
            -- Clear mouseover mode
            mouseoverEnabled = false
            mouseoverLastGUID = nil
        end
        
        -- Update preferred target
        self:UpdatePreferredTarget()
    end
}

-- On combat start
function MouseoverManager:OnCombatStart()
    inCombat = true
    self:UpdateSmartTargetCache()
}

-- On combat end
function MouseoverManager:OnCombatEnd()
    inCombat = false
    self:UpdateSmartTargetCache()
}

-- On unit health changed
function MouseoverManager:OnUnitHealthChanged(unit)
    -- Update unit health in storage
    if friendlyUnits[unit] then
        friendlyUnits[unit].health = UnitHealth(unit) / UnitHealthMax(unit) * 100
    elseif hostileUnits[unit] then
        hostileUnits[unit].health = UnitHealth(unit) / UnitHealthMax(unit) * 100
    end
    
    -- Update preferred target if needed
    if unit == "mouseover" or unit == "target" or unit == "focus" or (mouseoverUnits[UnitGUID(unit)] and mouseoverUnits[UnitGUID(unit)].unit == unit) then
        self:UpdatePreferredTarget()
    end
}

-- On unit spellcast start
function MouseoverManager:OnUnitSpellcastStart(unit)
    -- Update caster status for hostile units
    if hostileUnits[unit] then
        hostileUnits[unit].isCaster = true
        
        -- Update priority
        hostileUnits[unit].priority = 85 -- Casters get higher priority
    end
    
    -- Update preferred target if needed
    if unit == "mouseover" or unit == "target" or unit == "focus" or (mouseoverUnits[UnitGUID(unit)] and mouseoverUnits[UnitGUID(unit)].unit == unit) then
        self:UpdatePreferredTarget()
    end
}

-- On unit spellcast stop
function MouseoverManager:OnUnitSpellcastStop(unit)
    -- No need to update casting status, as we rely on IsUnitCaster for that
}

-- On player target changed
function MouseoverManager:OnPlayerTargetChanged()
    self:UpdateSmartTargetCache()
}

-- On player focus changed
function MouseoverManager:OnPlayerFocusChanged()
    self:UpdateSmartTargetCache()
}

-- On group roster update
function MouseoverManager:OnGroupRosterUpdate()
    -- This would update friendly unit roles
    -- For implementation simplicity, we'll just refresh on next tick
}

-- Update smart target cache
function MouseoverManager:UpdateSmartTargetCache()
    -- Store current target and mouseover for smart decisions
    smartTargetCache.lastTarget = UnitExists("target") and UnitGUID("target") or nil
    smartTargetCache.lastMouseover = currentMouseoverUnit and UnitGUID(currentMouseoverUnit) or nil
    smartTargetCache.lastDecisionTime = GetTime()
    
    -- Make a smart decision about preferred target
    smartTargetCache.lastDecision = self:DecidePreferredTarget()
}

-- Calculate friendly priority
function MouseoverManager:CalculateFriendlyPriority(unit)
    if not unit or not UnitExists(unit) then
        return 0
    end
    
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    local priority = 0
    
    -- Base priority based on role
    if self:IsUnitTank(unit) then
        priority = unitPriorities[CATEGORY_FRIENDLY]["TANK"]
    elseif self:IsUnitHealer(unit) then
        priority = unitPriorities[CATEGORY_FRIENDLY]["HEALER"]
    elseif UnitIsPlayer(unit) then
        priority = unitPriorities[CATEGORY_FRIENDLY]["DPS"]
    elseif UnitIsUnit(unit, "pet") then
        priority = unitPriorities[CATEGORY_FRIENDLY]["PET"]
    else
        priority = unitPriorities[CATEGORY_FRIENDLY]["NPC"]
    end
    
    -- Adjust based on settings
    if settings.friendlySettings.friendlyTargetPriority == "Low Health First" then
        -- Lower health gets higher priority
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        priority = priority + (100 - healthPct) / 2 -- Up to +50 for low health
    elseif settings.friendlySettings.friendlyTargetPriority == "Class Priority" then
        -- Adjust based on class
        local _, class = UnitClass(unit)
        if class == "PRIEST" or class == "PALADIN" or class == "DRUID" then
            priority = priority + 20 -- Higher priority for healing classes
        end
    elseif settings.friendlySettings.friendlyTargetPriority == "Role Priority" then
        -- Already covered in base priority
    elseif settings.friendlySettings.friendlyTargetPriority == "Distance Priority" then
        -- Closer units get higher priority
        local distance = 20 -- Placeholder, would calculate in a real addon
        priority = priority + (50 - distance) -- Up to +50 for closest units
    end
    
    -- Additional adjustments
    if settings.friendlySettings.prioritizeTank and self:IsUnitTank(unit) then
        priority = priority + 20
    end
    
    if settings.friendlySettings.prioritizeInCombat and UnitAffectingCombat(unit) then
        priority = priority + 15
    end
    
    return priority
end

-- Calculate hostile priority
function MouseoverManager:CalculateHostilePriority(unit)
    if not unit or not UnitExists(unit) then
        return 0
    end
    
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    local priority = 0
    
    -- Base priority based on type
    if self:IsUnitHealer(unit) then
        priority = unitPriorities[CATEGORY_HOSTILE]["HEALER"]
    elseif self:IsUnitCaster(unit) then
        priority = unitPriorities[CATEGORY_HOSTILE]["CASTER"]
    elseif UnitIsPlayer(unit) then
        priority = unitPriorities[CATEGORY_HOSTILE]["PLAYER"]
    elseif self:IsEliteUnit(unit) then
        priority = unitPriorities[CATEGORY_HOSTILE]["ELITE"]
    elseif UnitIsUnit(unit, "playerpet") then
        priority = unitPriorities[CATEGORY_HOSTILE]["PET"]
    else
        priority = unitPriorities[CATEGORY_HOSTILE]["NORMAL"]
    end
    
    -- Adjust based on settings
    if settings.hostileSettings.hostileTargetPriority == "Low Health First" then
        -- Lower health gets higher priority
        local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
        priority = priority + (100 - healthPct) / 2 -- Up to +50 for low health
    elseif settings.hostileSettings.hostileTargetPriority == "Class Priority" then
        -- Adjust based on class
        local _, class = UnitClass(unit)
        if class == "PRIEST" or class == "MAGE" or class == "WARLOCK" then
            priority = priority + 20 -- Higher priority for caster classes
        end
    elseif settings.hostileSettings.hostileTargetPriority == "Casting Priority" then
        -- Higher priority for casting units
        if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
            priority = priority + 30
        end
    elseif settings.hostileSettings.hostileTargetPriority == "Distance Priority" then
        -- Closer units get higher priority
        local distance = 20 -- Placeholder, would calculate in a real addon
        priority = priority + (50 - distance) -- Up to +50 for closest units
    end
    
    -- Additional adjustments
    if settings.hostileSettings.prioritizeCasters and self:IsUnitCaster(unit) then
        priority = priority + 20
    end
    
    if settings.hostileSettings.prioritizeImportantNPCs and self:IsImportantNPC(unit) then
        priority = priority + 25
    end
    
    return priority
end

-- Update preferred target
function MouseoverManager:UpdatePreferredTarget()
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Simple modes first
    if settings.generalSettings.targetPriorityMode == "Mouseover First" then
        if mouseoverEnabled and (currentMouseoverUnit or mouseoverLastGUID) then
            mouseoverPreferredTarget = currentMouseoverUnit or self:FindUnitByGUID(mouseoverLastGUID)
        else
            mouseoverPreferredTarget = "target"
        end
    elseif settings.generalSettings.targetPriorityMode == "Target First" then
        if UnitExists("target") then
            mouseoverPreferredTarget = "target"
        elseif mouseoverEnabled and (currentMouseoverUnit or mouseoverLastGUID) then
            mouseoverPreferredTarget = currentMouseoverUnit or self:FindUnitByGUID(mouseoverLastGUID)
        else
            mouseoverPreferredTarget = nil
        end
    elseif settings.generalSettings.targetPriorityMode == "Friendly/Hostile Split" then
        -- For healing/friendly spells, prefer mouseover
        -- For damage/hostile spells, prefer target
        mouseoverPreferredTarget = {
            [CATEGORY_FRIENDLY] = mouseoverEnabled and (currentMouseoverUnit or self:FindUnitByGUID(mouseoverLastGUID)) or "target",
            [CATEGORY_HOSTILE] = UnitExists("target") and "target" or (mouseoverEnabled and (currentMouseoverUnit or self:FindUnitByGUID(mouseoverLastGUID)) or nil)
        }
    else -- Smart Priority
        mouseoverPreferredTarget = self:DecidePreferredTarget()
    end
}

-- Decide preferred target using smart logic
function MouseoverManager:DecidePreferredTarget()
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    local preferredTarget = nil
    
    -- If we have a recent decision, use it
    if settings.generalSettings.targetPriorityMode == "Smart Priority" then
        local now = GetTime()
        if smartTargetCache.lastDecision and 
           now - smartTargetCache.lastDecisionTime < 1.0 and
           ((UnitExists("target") and UnitGUID("target") == smartTargetCache.lastTarget) or (not UnitExists("target") and not smartTargetCache.lastTarget)) and
           ((currentMouseoverUnit and UnitGUID(currentMouseoverUnit) == smartTargetCache.lastMouseover) or (not currentMouseoverUnit and not smartTargetCache.lastMouseover)) then
            -- Use cached decision if conditions haven't changed
            return smartTargetCache.lastDecision
        end
    end
    
    -- Consider mouseover target
    local mouseoverTarget = currentMouseoverUnit or (mouseoverLastGUID and self:FindUnitByGUID(mouseoverLastGUID))
    
    -- Calculate priorities
    local targetPriority = UnitExists("target") and (UnitCanAttack("player", "target") and self:CalculateHostilePriority("target") or self:CalculateFriendlyPriority("target")) or 0
    local mouseoverPriority = mouseoverTarget and UnitExists(mouseoverTarget) and (UnitCanAttack("player", mouseoverTarget) and self:CalculateHostilePriority(mouseoverTarget) or self:CalculateFriendlyPriority(mouseoverTarget)) or 0
    
    -- Choose the higher priority
    if mouseoverPriority > targetPriority + 10 then
        preferredTarget = mouseoverTarget
    elseif targetPriority > 0 then
        preferredTarget = "target"
    elseif mouseoverPriority > 0 then
        preferredTarget = mouseoverTarget
    else
        preferredTarget = nil
    end
    
    -- Store in cache
    smartTargetCache.lastDecision = preferredTarget
    smartTargetCache.lastDecisionTime = GetTime()
    
    return preferredTarget
end

-- Find unit by GUID
function MouseoverManager:FindUnitByGUID(guid)
    if not guid then
        return nil
    end
    
    -- Check common units
    if UnitExists("target") and UnitGUID("target") == guid then
        return "target"
    elseif UnitExists("focus") and UnitGUID("focus") == guid then
        return "focus"
    elseif UnitExists("mouseover") and UnitGUID("mouseover") == guid then
        return "mouseover"
    elseif UnitGUID("player") == guid then
        return "player"
    end
    
    -- Check mouseover units cache
    if mouseoverUnits[guid] then
        return mouseoverUnits[guid].unit
    end
    
    -- Check party/raid
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        local count = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            if UnitExists(unit) and UnitGUID(unit) == guid then
                return unit
            end
        end
    end
    
    -- Check nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    return nil
end

-- Is unit a tank
function MouseoverManager:IsUnitTank(unit)
    if not UnitExists(unit) then
        return false
    end
    
    -- Check role
    local role = UnitGroupRolesAssigned(unit)
    if role == "TANK" then
        return true
    end
    
    -- Check spec
    local _, class = UnitClass(unit)
    local specIndex = GetSpecialization()
    
    if class and specIndex then
        if (class == "WARRIOR" and specIndex == 3) or     -- Protection Warrior
           (class == "PALADIN" and specIndex == 2) or     -- Protection Paladin
           (class == "DRUID" and specIndex == 3) or       -- Guardian Druid
           (class == "MONK" and specIndex == 1) or        -- Brewmaster Monk
           (class == "DEATHKNIGHT" and specIndex == 1) or -- Blood Death Knight
           (class == "DEMONHUNTER" and specIndex == 2) then -- Vengeance Demon Hunter
            return true
        end
    end
    
    return false
end

-- Is unit a healer
function MouseoverManager:IsUnitHealer(unit)
    if not UnitExists(unit) then
        return false
    end
    
    -- Check role
    local role = UnitGroupRolesAssigned(unit)
    if role == "HEALER" then
        return true
    end
    
    -- Check spec
    local _, class = UnitClass(unit)
    local specIndex = GetSpecialization()
    
    if class and specIndex then
        if (class == "PRIEST" and (specIndex == 1 or specIndex == 2)) or -- Discipline or Holy Priest
           (class == "DRUID" and specIndex == 4) or                      -- Restoration Druid
           (class == "PALADIN" and specIndex == 1) or                    -- Holy Paladin
           (class == "SHAMAN" and specIndex == 3) or                     -- Restoration Shaman
           (class == "MONK" and specIndex == 2) or                       -- Mistweaver Monk
           (class == "EVOKER" and specIndex == 2) then                   -- Preservation Evoker
            return true
        end
    end
    
    return false
end

-- Is unit a caster
function MouseoverManager:IsUnitCaster(unit)
    if not UnitExists(unit) then
        return false
    end
    
    -- Check if unit is currently casting
    if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
        return true
    end
    
    -- Check class for player units
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or class == "EVOKER" or class == "SHAMAN" or class == "DRUID" then
            return true
        end
    end
    
    -- Check for caster NPC types
    local creatureType = UnitCreatureType(unit)
    if creatureType and (creatureType == "Humanoid" or creatureType == "Demon" or creatureType == "Elemental") then
        -- These types often include casters
        return true
    end
    
    return false
end

-- Is elite unit
function MouseoverManager:IsEliteUnit(unit)
    if not UnitExists(unit) then
        return false
    end
    
    -- Check classification
    local classification = UnitClassification(unit)
    return classification == "elite" or classification == "rareelite" or classification == "worldboss"
end

-- Is important NPC
function MouseoverManager:IsImportantNPC(unit)
    if not UnitExists(unit) then
        return false
    end
    
    -- Check classification
    local classification = UnitClassification(unit)
    if classification == "rare" or classification == "rareelite" or classification == "worldboss" then
        return true
    end
    
    -- Check for quest NPCs
    if UnitIsQuestBoss(unit) then
        return true
    end
    
    -- Check for specific NPC types
    -- This would be more comprehensive in a real addon
    
    return false
end

-- Check if spell is a mouseover spell
function MouseoverManager:IsMouseoverSpell(spellID, category)
    if not spellID then
        return false
    end
    
    if category == CATEGORY_FRIENDLY then
        return mouseoverSpells.healingSpells[spellID] or mouseoverSpells.utilitySpells[spellID]
    elseif category == CATEGORY_HOSTILE then
        return mouseoverSpells.damageSpells[spellID] or mouseoverSpells.utilitySpells[spellID]
    else
        return mouseoverSpells.healingSpells[spellID] or mouseoverSpells.damageSpells[spellID] or mouseoverSpells.utilitySpells[spellID]
    end
end

-- Check if spell is a target of mouseover spell
function MouseoverManager:IsTargetOfMouseoverSpell(spellID)
    return targetOfMouseoverSpells[spellID] or false
end

-- Get preferred cast target for spell
function MouseoverManager:GetPreferredCastTarget(spellID)
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if mouseover casting is disabled
    if not settings.generalSettings.enableMouseoverCasting then
        return "target"
    end
    
    -- Determine spell category (friendly or hostile)
    local category = nil
    
    if mouseoverSpells.healingSpells[spellID] then
        category = CATEGORY_FRIENDLY
    elseif mouseoverSpells.damageSpells[spellID] then
        category = CATEGORY_HOSTILE
    elseif mouseoverSpells.utilitySpells[spellID] then
        -- Check spell attributes to determine category
        category = self:GetSpellCategory(spellID)
    end
    
    if not category then
        -- Not a mouseover spell, use target
        return "target"
    end
    
    -- Check if this category is enabled
    if category == CATEGORY_FRIENDLY and not settings.friendlySettings.enableFriendlyMouseover then
        return "target"
    elseif category == CATEGORY_HOSTILE and not settings.hostileSettings.enableHostileMouseover then
        return "target"
    end
    
    -- Check if spell is allowed
    if category == CATEGORY_FRIENDLY and not settings.friendlySettings.enableMouseoverHealing and mouseoverSpells.healingSpells[spellID] then
        return "target"
    elseif category == CATEGORY_HOSTILE and not settings.hostileSettings.enableMouseoverDamage and mouseoverSpells.damageSpells[spellID] then
        return "target"
    end
    
    -- Check if spell is a target of mouseover spell
    if settings.advancedSettings.enableTargetOfMouseover and self:IsTargetOfMouseoverSpell(spellID) and mouseoverTargetOfTarget then
        local unit = self:FindUnitByGUID(mouseoverTargetOfTarget.guid)
        if unit then
            return unit
        end
    end
    
    -- Use preferred target based on mode
    if not mouseoverPreferredTarget then
        return "target"
    elseif type(mouseoverPreferredTarget) == "table" then
        -- Friendly/Hostile split mode
        return mouseoverPreferredTarget[category] or "target"
    else
        -- Any other mode
        return mouseoverPreferredTarget
    end
}

-- Get spell category
function MouseoverManager:GetSpellCategory(spellID)
    -- This would check if a spell is beneficial or harmful
    -- For implementation simplicity, we'll check if it appears in the friendly or hostile lists
    
    if mouseoverSpells.healingSpells[spellID] then
        return CATEGORY_FRIENDLY
    elseif mouseoverSpells.damageSpells[spellID] then
        return CATEGORY_HOSTILE
    else
        -- We need to check the spell's attributes
        local isHelpful = IsHelpfulSpell(GetSpellInfo(spellID))
        local isHarmful = IsHarmfulSpell(GetSpellInfo(spellID))
        
        if isHelpful and not isHarmful then
            return CATEGORY_FRIENDLY
        elseif isHarmful and not isHelpful then
            return CATEGORY_HOSTILE
        else
            -- Could be both or neither - default to hostile
            return CATEGORY_HOSTILE
        end
    end
end

-- Get mouseover healable unit
function MouseoverManager:GetMouseoverHealableUnit()
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if mouseover healing is disabled
    if not settings.friendlySettings.enableMouseoverHealing or not settings.generalSettings.enableMouseoverCasting then
        return "target"
    end
    
    -- Use preferred friendly target
    if not mouseoverPreferredTarget then
        return "target"
    elseif type(mouseoverPreferredTarget) == "table" then
        -- Friendly/Hostile split mode
        return mouseoverPreferredTarget[CATEGORY_FRIENDLY] or "target"
    else
        -- Any other mode
        return mouseoverPreferredTarget
    end
}

-- Get mouseover damageable unit
function MouseoverManager:GetMouseoverDamageableUnit()
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if mouseover damage is disabled
    if not settings.hostileSettings.enableMouseoverDamage or not settings.generalSettings.enableMouseoverCasting then
        return "target"
    end
    
    -- Use preferred hostile target
    if not mouseoverPreferredTarget then
        return "target"
    elseif type(mouseoverPreferredTarget) == "table" then
        -- Friendly/Hostile split mode
        return mouseoverPreferredTarget[CATEGORY_HOSTILE] or "target"
    else
        -- Any other mode
        return mouseoverPreferredTarget
    end
}

-- Is mouseover enabled
function MouseoverManager:IsMouseoverEnabled()
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    return settings.generalSettings.enableMouseoverCasting and mouseoverEnabled
}

-- Get mouseover target of target
function MouseoverManager:GetMouseoverTargetOfTarget()
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if target of mouseover is disabled
    if not settings.advancedSettings.enableTargetOfMouseover then
        return nil
    end
    
    if mouseoverTargetOfTarget then
        local unit = self:FindUnitByGUID(mouseoverTargetOfTarget.guid)
        if unit then
            return unit
        end
    end
    
    return nil
}

-- Register mouseover spells
function MouseoverManager:RegisterMouseoverSpell(spellID, category, isTargetOfMouseover)
    if not spellID or not category then
        return
    end
    
    if category == CATEGORY_FRIENDLY then
        mouseoverSpells.healingSpells[spellID] = true
    elseif category == CATEGORY_HOSTILE then
        mouseoverSpells.damageSpells[spellID] = true
    else
        mouseoverSpells.utilitySpells[spellID] = true
    end
    
    if isTargetOfMouseover then
        targetOfMouseoverSpells[spellID] = true
    end
}

-- Unregister mouseover spell
function MouseoverManager:UnregisterMouseoverSpell(spellID)
    if not spellID then
        return
    end
    
    mouseoverSpells.healingSpells[spellID] = nil
    mouseoverSpells.damageSpells[spellID] = nil
    mouseoverSpells.utilitySpells[spellID] = nil
    targetOfMouseoverSpells[spellID] = nil
}

-- Cast with mouseover support
function MouseoverManager:CastWithMouseoverSupport(spellID, predicate)
    if not spellID then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if mouseover casting is disabled
    if not settings.generalSettings.enableMouseoverCasting then
        if predicate and not predicate("target") then
            return false
        end
        return API.CastSpellByID(spellID, "target")
    end
    
    -- Get preferred target
    local target = self:GetPreferredCastTarget(spellID)
    
    -- Check predicate if provided
    if predicate and not predicate(target) then
        return false
    end
    
    -- Cast the spell
    return API.CastSpellByID(spellID, target)
}

-- Cast friendly spell with mouseover support
function MouseoverManager:CastFriendlyWithMouseoverSupport(spellID, predicate)
    if not spellID then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if friendly mouseover is disabled
    if not settings.friendlySettings.enableFriendlyMouseover or not settings.generalSettings.enableMouseoverCasting then
        if predicate and not predicate("target") then
            return false
        end
        return API.CastSpellByID(spellID, "target")
    end
    
    -- Get healable unit
    local target = self:GetMouseoverHealableUnit()
    
    -- Check predicate if provided
    if predicate and not predicate(target) then
        return false
    end
    
    -- Cast the spell
    return API.CastSpellByID(spellID, target)
}

-- Cast hostile spell with mouseover support
function MouseoverManager:CastHostileWithMouseoverSupport(spellID, predicate)
    if not spellID then
        return false
    end
    
    local settings = ConfigRegistry:GetSettings("MouseoverManager")
    
    -- Skip if hostile mouseover is disabled
    if not settings.hostileSettings.enableHostileMouseover or not settings.generalSettings.enableMouseoverCasting then
        if predicate and not predicate("target") then
            return false
        end
        return API.CastSpellByID(spellID, "target")
    end
    
    -- Get damageable unit
    local target = self:GetMouseoverDamageableUnit()
    
    -- Check predicate if provided
    if predicate and not predicate(target) then
        return false
    end
    
    -- Cast the spell
    return API.CastSpellByID(spellID, target)
}

-- Return the module
return MouseoverManager