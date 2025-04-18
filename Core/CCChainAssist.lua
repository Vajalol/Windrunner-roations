------------------------------------------
-- WindrunnerRotations - CC Chain Assist
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local CCChainAssist = {}
WR.CCChainAssist = CCChainAssist

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local InterruptManager = WR.InterruptManager
local PvPManager = WR.PvPManager
local GroupRoleManager = WR.GroupRoleManager

-- Data storage
local isEnabled = true
local ccPriority = {}
local activeCCs = {}
local ccTargets = {}
local pendingCCs = {}
local ccHistory = {}
local ccBreakHistory = {}
local ccMonitorFrame = nil
local ccTrackingInterval = 0.1
local maxCCHistorySize = 50
local playerClass = nil
local playerCCs = {}
local instanceType = nil
local ccChains = {}
local ccDiminishingReturns = {}
local playerFractionalCC = false
local drCategories = {}
local lastCCCheck = 0
local ccCooldowns = {}
local targetCCImmunities = {}
local ccImmunityDuration = {}
local chainLock = {}
local ccGlobalCooldown = 0.5
local lastCCAttempt = 0
local isInChain = false
local currentChainTarget = nil
local targetCCDuration = {}
local targetCCResistance = {}
local enablePartyCoordination = true
local partyChainAssignments = {}
local smartChainEnabled = true
local communityDRData = {}
local lastDRUpdate = {}
local visualFeedbackEnabled = true
local failedCCNotifier = true
local successfulCCNotifier = true

-- CC types
local CC_TYPE_STUN = "stun"
local CC_TYPE_INCAPACITATE = "incapacitate"
local CC_TYPE_DISORIENT = "disorient"
local CC_TYPE_SILENCE = "silence"
local CC_TYPE_FEAR = "fear"
local CC_TYPE_ROOT = "root"
local CC_TYPE_DISARM = "disarm"
local CC_TYPE_SLOWCAST = "slowcast"

-- CC Categories for Diminishing Returns
local DR_STUN = "stun"
local DR_INCAPACITATE = "incapacitate"
local DR_DISORIENT = "disorient"
local DR_SILENCE = "silence"
local DR_FEAR = "fear"
local DR_ROOT = "root"
local DR_DISARM = "disarm"
local DR_NONE = "none"

-- Diminishing Return durations
local DR_REDUCTION_FIRST = 0.5      -- 50% duration on second application
local DR_REDUCTION_SECOND = 0.25    -- 25% duration on third application
local DR_REDUCTION_IMMUNE = 0       -- Immune on fourth application
local DR_RESET_TIMER = 18.0         -- DR resets after 18 seconds

-- Initialize the CC Chain Assist
function CCChainAssist:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize player CC abilities
    playerClass = select(2, UnitClass("player"))
    self:InitializePlayerCCs()
    
    -- Initialize diminishing returns categories
    self:InitializeDRCategories()
    
    -- Create CC monitor frame
    self:CreateCCMonitorFrame()
    
    API.PrintDebug("CC Chain Assist initialized")
    return true
end

-- Register settings
function CCChainAssist:RegisterSettings()
    ConfigRegistry:RegisterSettings("CCChainAssist", {
        generalSettings = {
            enableCCChainAssist = {
                displayName = "Enable CC Chain Assist",
                description = "Help coordinate CC chains in group settings",
                type = "toggle",
                default = true
            },
            enablePartyCoordination = {
                displayName = "Party Coordination",
                description = "Enable coordination of CC chains with party members",
                type = "toggle",
                default = true
            },
            smartChaining = {
                displayName = "Smart CC Chaining",
                description = "Intelligently chain CCs based on DR and effectiveness",
                type = "toggle",
                default = true
            },
            ccTrackingInterval = {
                displayName = "CC Tracking Interval",
                description = "How often to check for CC changes (seconds)",
                type = "slider",
                min = 0.05,
                max = 0.5,
                step = 0.05,
                default = 0.1
            }
        },
        ccPrioritySettings = {
            priorityHealer = {
                displayName = "Healer CC Priority",
                description = "Priority for CCing enemy healers",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 10
            },
            priorityDamage = {
                displayName = "Damage Dealer CC Priority",
                description = "Priority for CCing enemy damage dealers",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 7
            },
            priorityTank = {
                displayName = "Tank CC Priority",
                description = "Priority for CCing enemy tanks",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            },
            priorityDruid = {
                displayName = "Druid CC Priority",
                description = "Priority for CCing enemy druids",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 9
            },
            priorityRogue = {
                displayName = "Rogue CC Priority",
                description = "Priority for CCing enemy rogues",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 8
            },
            priorityShaman = {
                displayName = "Shaman CC Priority",
                description = "Priority for CCing enemy shamans",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 7
            }
        },
        ccChainSettings = {
            stunFirst = {
                displayName = "Stun First",
                description = "Use stuns as the first CC in a chain",
                type = "toggle",
                default = true
            },
            fearSecond = {
                displayName = "Fear Second",
                description = "Use fears as the second CC in a chain",
                type = "toggle",
                default = true
            },
            incapacitateThird = {
                displayName = "Incapacitate Third",
                description = "Use incapacitates as the third CC in a chain",
                type = "toggle",
                default = true
            },
            rootFourth = {
                displayName = "Root Fourth",
                description = "Use roots as the fourth CC in a chain",
                type = "toggle",
                default = false
            },
            silenceHealer = {
                displayName = "Silence Healer",
                description = "Prioritize silences for enemy healers",
                type = "toggle",
                default = true
            },
            disarmDamageDealer = {
                displayName = "Disarm Damage Dealer",
                description = "Prioritize disarms for enemy damage dealers",
                type = "toggle",
                default = true
            }
        },
        communicationSettings = {
            announceCC = {
                displayName = "Announce CC",
                description = "Announce CC usage to party/raid",
                type = "toggle",
                default = true
            },
            announceCCBreak = {
                displayName = "Announce CC Break",
                description = "Announce when CC is broken early",
                type = "toggle",
                default = true
            },
            announceCCChannel = {
                displayName = "Announcement Channel",
                description = "Channel to use for CC announcements",
                type = "dropdown",
                options = {"Party", "Raid", "Say", "Emote", "None"},
                default = "Party"
            },
            announceNextCC = {
                displayName = "Announce Next CC",
                description = "Announce who should use the next CC in the chain",
                type = "toggle",
                default = true
            },
            announceDR = {
                displayName = "Announce DR",
                description = "Announce diminishing returns information",
                type = "toggle",
                default = true
            }
        },
        visualSettings = {
            enableVisualFeedback = {
                displayName = "Visual Feedback",
                description = "Show visual feedback for CC status",
                type = "toggle",
                default = true
            },
            notifyFailedCC = {
                displayName = "Notify Failed CC",
                description = "Show notification when CC fails",
                type = "toggle",
                default = true
            },
            notifySuccessfulCC = {
                displayName = "Notify Successful CC",
                description = "Show notification when CC succeeds",
                type = "toggle",
                default = true
            },
            showCCDuration = {
                displayName = "Show CC Duration",
                description = "Show remaining CC duration on targets",
                type = "toggle",
                default = true
            },
            showDRStatus = {
                displayName = "Show DR Status",
                description = "Show diminishing returns status on targets",
                type = "toggle",
                default = true
            },
            ccAlertSound = {
                displayName = "CC Alert Sound",
                description = "Play sound when CC is ending soon",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Register for events
function CCChainAssist:RegisterEvents()
    -- Register for aura application/removal
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLog(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for unit events
    API.RegisterEvent("UNIT_AURA", function(unit)
        self:OnUnitAuraChanged(unit)
    end)
    
    -- Register for cast events
    API.RegisterEvent("UNIT_SPELLCAST_START", function(unit, castGUID, spellID)
        self:OnUnitCastStart(unit, castGUID, spellID)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, castGUID, spellID)
        self:OnUnitCastSucceeded(unit, castGUID, spellID)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_FAILED", function(unit, castGUID, spellID)
        self:OnUnitCastFailed(unit, castGUID, spellID)
    end)
    
    -- Register for target changed
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:OnTargetChanged()
    end)
    
    -- Register for focus changed
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:OnFocusChanged()
    end)
    
    -- Register for arena/instance events
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:OnPlayerEnteringWorld()
    end)
    
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
    
    API.RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", function()
        self:OnArenaPrep()
    end)
    
    API.RegisterEvent("ARENA_OPPONENT_UPDATE", function(unit, updateReason)
        self:OnArenaOpponentUpdate(unit, updateReason)
    end)
    
    -- Register for group events
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:OnGroupRosterUpdate()
    end)
    
    API.RegisterEvent("PARTY_MEMBER_DISABLE", function(unit)
        self:OnPartyMemberDisable(unit)
    end)
    
    API.RegisterEvent("PARTY_MEMBER_ENABLE", function(unit)
        self:OnPartyMemberEnable(unit)
    end)
    
    -- Create a ticker for CC monitoring
    ccMonitorFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= ccTrackingInterval then
            CCChainAssist:MonitorCCs()
            self.elapsed = 0
        end
    end)
}

-- Initialize player CC abilities
function CCChainAssist:InitializePlayerCCs()
    playerCCs = {}
    
    -- Define CC abilities by class
    local classCCs = {
        -- Mage CCs
        ["MAGE"] = {
            {spellID = 118, name = "Polymorph", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 60, range = 30, targetTypes = {"humanoid", "beast", "critter"}, priority = 8, isMainCC = true},
            {spellID = 82691, name = "Ring of Frost", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 10, range = 40, aoe = true, priority = 7, isMainCC = false},
            {spellID = 122, name = "Frost Nova", type = CC_TYPE_ROOT, drCategory = DR_ROOT, duration = 8, range = 12, aoe = true, priority = 5, isMainCC = false},
            {spellID = 157997, name = "Ice Nova", type = CC_TYPE_ROOT, drCategory = DR_ROOT, duration = 2, range = 40, priority = 4, isMainCC = false},
            {spellID = 31661, name = "Dragon's Breath", type = CC_TYPE_DISORIENT, drCategory = DR_DISORIENT, duration = 4, range = 12, aoe = true, priority = 6, isMainCC = false},
            {spellID = 2139, name = "Counterspell", type = CC_TYPE_SILENCE, drCategory = DR_SILENCE, duration = 6, range = 40, priority = 9, isMainCC = false},
        },
        
        -- Paladin CCs
        ["PALADIN"] = {
            {spellID = 853, name = "Hammer of Justice", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 6, range = 10, priority = 8, isMainCC = true},
            {spellID = 105421, name = "Blinding Light", type = CC_TYPE_DISORIENT, drCategory = DR_DISORIENT, duration = 6, range = 10, aoe = true, priority = 7, isMainCC = false},
            {spellID = 20066, name = "Repentance", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 60, range = 30, targetTypes = {"humanoid", "demon", "dragonkin", "giant", "undead"}, priority = 9, isMainCC = true},
            {spellID = 10326, name = "Turn Evil", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 40, range = 20, targetTypes = {"demon", "undead"}, priority = 5, isMainCC = false},
        },
        
        -- Warrior CCs
        ["WARRIOR"] = {
            {spellID = 5246, name = "Intimidating Shout", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 8, range = 8, aoe = true, priority = 7, isMainCC = true},
            {spellID = 132169, name = "Storm Bolt", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 4, range = 30, priority = 8, isMainCC = true},
            {spellID = 107570, name = "Storm Bolt", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 4, range = 30, priority = 8, isMainCC = false},
            {spellID = 46968, name = "Shockwave", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 2, range = 10, aoe = true, priority = 6, isMainCC = false},
        },
        
        -- Priest CCs
        ["PRIEST"] = {
            {spellID = 605, name = "Mind Control", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 30, range = 30, targetTypes = {"humanoid"}, priority = 9, isMainCC = true},
            {spellID = 8122, name = "Psychic Scream", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 8, range = 8, aoe = true, priority = 7, isMainCC = true},
            {spellID = 15487, name = "Silence", type = CC_TYPE_SILENCE, drCategory = DR_SILENCE, duration = 5, range = 30, priority = 8, isMainCC = false},
            {spellID = 64044, name = "Psychic Horror", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 4, range = 30, priority = 6, isMainCC = false},
            {spellID = 205369, name = "Mind Bomb", type = CC_TYPE_DISORIENT, drCategory = DR_DISORIENT, duration = 4, range = 30, aoe = true, priority = 7, isMainCC = false},
        },
        
        -- Rogue CCs
        ["ROGUE"] = {
            {spellID = 6770, name = "Sap", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 60, range = 10, targetTypes = {"humanoid", "beast", "demon", "dragonkin"}, stealth = true, priority = 9, isMainCC = true},
            {spellID = 2094, name = "Blind", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 8, range = 15, priority = 8, isMainCC = true},
            {spellID = 1833, name = "Cheap Shot", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 4, range = 5, stealth = true, priority = 7, isMainCC = false},
            {spellID = 408, name = "Kidney Shot", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 6, range = 5, comboPoints = true, priority = 8, isMainCC = false},
            {spellID = 1776, name = "Gouge", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 4, range = 5, priority = 6, isMainCC = false},
        },
        
        -- Other classes would be defined similarly...
        
        -- Warlock CCs
        ["WARLOCK"] = {
            {spellID = 5782, name = "Fear", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 20, range = 30, priority = 8, isMainCC = true},
            {spellID = 6789, name = "Mortal Coil", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 3, range = 20, priority = 7, isMainCC = false},
            {spellID = 5484, name = "Howl of Terror", type = CC_TYPE_FEAR, drCategory = DR_FEAR, duration = 8, range = 10, aoe = true, priority = 6, isMainCC = false},
            {spellID = 710, name = "Banish", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 30, range = 30, targetTypes = {"demon", "elemental"}, priority = 9, isMainCC = true},
            {spellID = 19505, name = "Devour Magic", type = CC_TYPE_SILENCE, drCategory = DR_SILENCE, duration = 2, range = 30, priority = 5, isMainCC = false, petAbility = true},
            {spellID = 115268, name = "Mesmerize", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 30, range = 20, targetTypes = {"humanoid", "beast"}, priority = 8, isMainCC = true, petAbility = true, petType = "succubus"},
        },
        
        -- Druid CCs
        ["DRUID"] = {
            {spellID = 339, name = "Entangling Roots", type = CC_TYPE_ROOT, drCategory = DR_ROOT, duration = 30, range = 35, priority = 7, isMainCC = true},
            {spellID = 2637, name = "Hibernate", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 40, range = 30, targetTypes = {"beast", "dragonkin"}, priority = 8, isMainCC = true},
            {spellID = 33786, name = "Cyclone", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 6, range = 20, priority = 9, isMainCC = true},
            {spellID = 5211, name = "Mighty Bash", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 5, range = 5, priority = 8, isMainCC = false},
            {spellID = 102359, name = "Mass Entanglement", type = CC_TYPE_ROOT, drCategory = DR_ROOT, duration = 30, range = 30, aoe = true, priority = 6, isMainCC = false},
            {spellID = 132469, name = "Typhoon", type = CC_TYPE_DISORIENT, drCategory = DR_DISORIENT, duration = 6, range = 15, aoe = true, priority = 7, isMainCC = false},
        },
        
        -- Hunter CCs
        ["HUNTER"] = {
            {spellID = 3355, name = "Freezing Trap", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 60, range = 40, aoe = true, trap = true, priority = 9, isMainCC = true},
            {spellID = 19386, name = "Wyvern Sting", type = CC_TYPE_INCAPACITATE, drCategory = DR_INCAPACITATE, duration = 30, range = 40, priority = 8, isMainCC = true},
            {spellID = 5116, name = "Concussive Shot", type = CC_TYPE_ROOT, drCategory = DR_ROOT, duration = 6, range = 40, priority = 5, isMainCC = false},
            {spellID = 24394, name = "Intimidation", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 3, range = 30, priority = 7, isMainCC = false, petAbility = true},
            {spellID = 19577, name = "Intimidation", type = CC_TYPE_STUN, drCategory = DR_STUN, duration = 3, range = 5, priority = 7, isMainCC = false, petAbility = true},
        },
    }
    
    -- Get abilities for player's class
    if classCCs[playerClass] then
        playerCCs = classCCs[playerClass]
    end
    
    -- Sort by priority
    table.sort(playerCCs, function(a, b) return a.priority > b.priority end)
}

-- Initialize diminishing returns categories
function CCChainAssist:InitializeDRCategories()
    drCategories = {
        [DR_STUN] = {
            name = "Stun",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        },
        [DR_INCAPACITATE] = {
            name = "Incapacitate",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        },
        [DR_DISORIENT] = {
            name = "Disorient",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        },
        [DR_SILENCE] = {
            name = "Silence",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        },
        [DR_FEAR] = {
            name = "Fear",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        },
        [DR_ROOT] = {
            name = "Root",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        },
        [DR_DISARM] = {
            name = "Disarm",
            resetTime = DR_RESET_TIMER,
            reductions = {1.0, DR_REDUCTION_FIRST, DR_REDUCTION_SECOND, DR_REDUCTION_IMMUNE}
        }
    }
}

-- Create CC monitor frame
function CCChainAssist:CreateCCMonitorFrame()
    ccMonitorFrame = CreateFrame("Frame", "WindrunnerRotationsCCMonitorFrame")
    ccMonitorFrame:Hide()
    ccMonitorFrame.elapsed = 0
}

-- Process combat log
function CCChainAssist:ProcessCombatLog(...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, _, auraType = ...
    
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Handle CC application
    if event == "SPELL_AURA_APPLIED" and (auraType == "DEBUFF") then
        self:ProcessCCApplication(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    
    -- Handle CC removal
    elseif event == "SPELL_AURA_REMOVED" and (auraType == "DEBUFF") then
        self:ProcessCCRemoval(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    
    -- Handle CC breaks
    elseif event == "SPELL_AURA_BROKEN" or event == "SPELL_AURA_BROKEN_SPELL" then
        self:ProcessCCBreak(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    
    -- Handle spell damage for tracking CC breaks
    elseif event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" then
        self:ProcessSpellDamage(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    
    -- Handle spell healing for tracking CC breaks
    elseif event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        self:ProcessSpellHeal(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    
    -- Handle unit death
    elseif event == "UNIT_DIED" then
        self:ProcessUnitDeath(destGUID, destName)
    end
}

-- Process CC application
function CCChainAssist:ProcessCCApplication(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Check if this is a CC spell
    local ccType, duration, drCategory = self:GetCCInfo(spellID)
    
    if not ccType then
        return
    end
    
    -- Get current time
    local now = GetTime()
    
    -- Create a new active CC entry
    local ccInfo = {
        sourceGUID = sourceGUID,
        sourceName = sourceName,
        destGUID = destGUID,
        destName = destName,
        spellID = spellID,
        spellName = spellName,
        ccType = ccType,
        drCategory = drCategory,
        startTime = now,
        endTime = now + duration,
        duration = duration,
        broken = false,
        immunityEnd = nil
    }
    
    -- If the source is player, track as a successful CC
    if sourceGUID == UnitGUID("player") then
        -- Add to history
        table.insert(ccHistory, ccInfo)
        
        -- Trim history if needed
        if #ccHistory > maxCCHistorySize then
            table.remove(ccHistory, 1)
        end
        
        -- Show success notification
        if ConfigRegistry:GetSettings("CCChainAssist").visualSettings.notifySuccessfulCC then
            API.PrintMessage("Successfully CC'd " .. destName .. " with " .. spellName)
        end
        
        -- Handle CC chain coordination
        self:HandleCCChainCoordination(destGUID, ccInfo)
    end
    
    -- Add to active CCs
    if not activeCCs[destGUID] then
        activeCCs[destGUID] = {}
    end
    
    activeCCs[destGUID][spellID] = ccInfo
    
    -- Update DR for this target
    self:UpdateDiminishingReturns(destGUID, drCategory)
    
    -- Announce CC if configured
    self:AnnounceCCApplication(ccInfo)
}

-- Process CC removal
function CCChainAssist:ProcessCCRemoval(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Check if this is a tracked CC
    if not activeCCs[destGUID] or not activeCCs[destGUID][spellID] then
        return
    end
    
    local ccInfo = activeCCs[destGUID][spellID]
    
    -- Check if CC ended early
    local now = GetTime()
    local earlyEnd = ccInfo.endTime > now
    
    -- If it ended early and wasn't marked as broken, it might be a special case
    if earlyEnd and not ccInfo.broken then
        -- Mark as broken with unknown cause
        ccInfo.broken = true
        ccInfo.breakType = "unknown"
    end
    
    -- If the source is player, track removal
    if ccInfo.sourceGUID == UnitGUID("player") then
        -- Update history entry
        for i, entry in ipairs(ccHistory) do
            if entry.destGUID == destGUID and entry.spellID == spellID and entry.startTime == ccInfo.startTime then
                entry.broken = ccInfo.broken
                entry.breakType = ccInfo.breakType
                entry.actualDuration = now - entry.startTime
                break
            end
        end
        
        -- Announce if it was broken early
        if earlyEnd and ccInfo.broken then
            self:AnnounceCCBreak(ccInfo)
        end
    end
    
    -- Remove from active CCs
    activeCCs[destGUID][spellID] = nil
    
    -- Remove empty target entry
    if not next(activeCCs[destGUID]) then
        activeCCs[destGUID] = nil
    end
    
    -- Handle immunity after CC
    if ccInfo.drCategory then
        -- Some CCs cause temporary immunity, track that
        ccImmunityDuration[destGUID] = ccImmunityDuration[destGUID] or {}
        ccImmunityDuration[destGUID][ccInfo.drCategory] = now + 2.0 -- 2 second immunity
    end
    
    -- Handle next CC in chain if needed
    if ccInfo.sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("player") then
        self:HandleNextCCInChain(destGUID)
    end
}

-- Process CC break
function CCChainAssist:ProcessCCBreak(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Find the CC that was broken
    if not activeCCs[destGUID] then
        return
    end
    
    for ccSpellID, ccInfo in pairs(activeCCs[destGUID]) do
        -- Mark as broken
        ccInfo.broken = true
        ccInfo.breakType = "dispel"
        ccInfo.breakerGUID = sourceGUID
        ccInfo.breakerName = sourceName
        ccInfo.breakSpellID = spellID
        ccInfo.breakSpellName = spellName
        
        -- Add to break history
        table.insert(ccBreakHistory, {
            ccInfo = ccInfo,
            breakTime = GetTime(),
            breakerGUID = sourceGUID,
            breakerName = sourceName,
            breakSpellID = spellID,
            breakSpellName = spellName
        })
        
        -- Trim break history if needed
        if #ccBreakHistory > maxCCHistorySize then
            table.remove(ccBreakHistory, 1)
        end
        
        -- Announce the break
        self:AnnounceCCBreak(ccInfo)
    end
}

-- Process spell damage for tracking CC breaks
function CCChainAssist:ProcessSpellDamage(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Check if the damage could break a CC
    if not activeCCs[destGUID] then
        return
    end
    
    for ccSpellID, ccInfo in pairs(activeCCs[destGUID]) do
        -- Check if this CC can be broken by damage
        if self:CanCCBeBreakByDamage(ccInfo.ccType) then
            -- Mark as broken
            ccInfo.broken = true
            ccInfo.breakType = "damage"
            ccInfo.breakerGUID = sourceGUID
            ccInfo.breakerName = sourceName
            ccInfo.breakSpellID = spellID
            ccInfo.breakSpellName = spellName
            
            -- Add to break history
            table.insert(ccBreakHistory, {
                ccInfo = ccInfo,
                breakTime = GetTime(),
                breakerGUID = sourceGUID,
                breakerName = sourceName,
                breakSpellID = spellID,
                breakSpellName = spellName
            })
            
            -- Trim break history if needed
            if #ccBreakHistory > maxCCHistorySize then
                table.remove(ccBreakHistory, 1)
            end
            
            -- Announce the break
            self:AnnounceCCBreak(ccInfo)
            
            -- Force remove the CC from active tracking
            activeCCs[destGUID][ccSpellID] = nil
            
            -- Remove empty target entry
            if not next(activeCCs[destGUID]) then
                activeCCs[destGUID] = nil
            end
        end
    end
}

-- Process spell heal for tracking CC breaks
function CCChainAssist:ProcessSpellHeal(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Currently, no CC is broken by healing, but the function is included for completeness
}

-- Process unit death
function CCChainAssist:ProcessUnitDeath(destGUID, destName)
    -- Clear any active CCs on the dead unit
    if activeCCs[destGUID] then
        activeCCs[destGUID] = nil
    end
    
    -- Clear any pending CCs on the dead unit
    if pendingCCs[destGUID] then
        pendingCCs[destGUID] = nil
    end
    
    -- Clear any CC targets
    for i = #ccTargets, 1, -1 do
        if ccTargets[i].destGUID == destGUID then
            table.remove(ccTargets, i)
        end
    end
    
    -- Clear any chain locks
    chainLock[destGUID] = nil
    
    -- Clear DR tracking
    ccDiminishingReturns[destGUID] = nil
    lastDRUpdate[destGUID] = nil
    ccImmunityDuration[destGUID] = nil
    
    -- If this was the current chain target, clear it
    if currentChainTarget == destGUID then
        currentChainTarget = nil
        isInChain = false
    end
}

-- On unit aura changed
function CCChainAssist:OnUnitAuraChanged(unit)
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Check unit's auras for CC effects
    if UnitExists(unit) then
        local unitGUID = UnitGUID(unit)
        
        -- Scan for CC debuffs
        local i = 1
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellID = UnitDebuff(unit, i)
        
        while name do
            -- Check if this is a CC spell
            local ccType, _, drCategory = self:GetCCInfo(spellID)
            
            if ccType then
                -- Check if we're already tracking this CC
                if not activeCCs[unitGUID] or not activeCCs[unitGUID][spellID] then
                    -- Get source info
                    local sourceGUID = source and UnitGUID(source) or nil
                    local sourceName = source and UnitName(source) or "Unknown"
                    
                    -- Create CC info
                    local ccInfo = {
                        sourceGUID = sourceGUID,
                        sourceName = sourceName,
                        destGUID = unitGUID,
                        destName = UnitName(unit),
                        spellID = spellID,
                        spellName = name,
                        ccType = ccType,
                        drCategory = drCategory,
                        startTime = expirationTime - duration,
                        endTime = expirationTime,
                        duration = duration,
                        broken = false,
                        immunityEnd = nil
                    }
                    
                    -- Add to active CCs
                    if not activeCCs[unitGUID] then
                        activeCCs[unitGUID] = {}
                    end
                    
                    activeCCs[unitGUID][spellID] = ccInfo
                    
                    -- Update DR for this target
                    if drCategory then
                        self:UpdateDiminishingReturns(unitGUID, drCategory)
                    end
                end
            end
            
            -- Move to next aura
            i = i + 1
            name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
            nameplateShowPersonal, spellID = UnitDebuff(unit, i)
        end
    end
}

-- On unit cast start
function CCChainAssist:OnUnitCastStart(unit, castGUID, spellID)
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Check if the player is casting a CC
    if unit == "player" then
        -- Check if this is a CC spell
        local ccType, duration, drCategory = self:GetCCInfo(spellID)
        
        if ccType then
            -- Get target info
            local targetUnit = "target"
            if UnitExists(targetUnit) then
                local targetGUID = UnitGUID(targetUnit)
                local targetName = UnitName(targetUnit)
                
                -- Check for DR on this target
                local drFactor = self:GetDRFactor(targetGUID, drCategory)
                
                -- Check for immunity
                local isImmune = self:IsTargetImmuneToCC(targetGUID, drCategory, ccType)
                
                if isImmune then
                    -- Warn about immunity
                    API.PrintMessage(targetName .. " is immune to " .. GetSpellInfo(spellID))
                elseif drFactor < 0.5 then
                    -- Warn about significant DR
                    API.PrintMessage(targetName .. " has strong diminishing returns on " .. GetSpellInfo(spellID) .. " (" .. math.floor(drFactor * 100) .. "% duration)")
                end
                
                -- Add to pending CCs
                pendingCCs[targetGUID] = pendingCCs[targetGUID] or {}
                pendingCCs[targetGUID][spellID] = {
                    sourceGUID = UnitGUID("player"),
                    sourceName = UnitName("player"),
                    destGUID = targetGUID,
                    destName = targetName,
                    spellID = spellID,
                    spellName = GetSpellInfo(spellID),
                    ccType = ccType,
                    drCategory = drCategory,
                    startTime = GetTime(),
                    duration = duration * drFactor,
                    drFactor = drFactor
                }
            end
        end
    end
}

-- On unit cast succeeded
function CCChainAssist:OnUnitCastSucceeded(unit, castGUID, spellID)
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Check if the player successfully cast a CC
    if unit == "player" then
        -- Check if this is a CC spell
        local ccType = self:GetCCInfo(spellID)
        
        if ccType then
            -- Get target info
            local targetUnit = "target"
            if UnitExists(targetUnit) then
                local targetGUID = UnitGUID(targetUnit)
                
                -- Record the last CC attempt time
                lastCCAttempt = GetTime()
                
                -- Check if this CC is part of a chain
                if isInChain and currentChainTarget == targetGUID then
                    -- Update chain status
                    self:UpdateChainStatus(targetGUID, spellID)
                end
            end
        end
    end
}

-- On unit cast failed
function CCChainAssist:OnUnitCastFailed(unit, castGUID, spellID)
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Check if the player failed to cast a CC
    if unit == "player" then
        -- Check if this is a CC spell
        local ccType = self:GetCCInfo(spellID)
        
        if ccType then
            -- Get target info
            local targetUnit = "target"
            if UnitExists(targetUnit) then
                local targetGUID = UnitGUID(targetUnit)
                
                -- Clean up pending CC
                if pendingCCs[targetGUID] and pendingCCs[targetGUID][spellID] then
                    pendingCCs[targetGUID][spellID] = nil
                    
                    -- Show failed notification
                    if ConfigRegistry:GetSettings("CCChainAssist").visualSettings.notifyFailedCC then
                        API.PrintMessage("Failed to CC " .. UnitName(targetUnit) .. " with " .. GetSpellInfo(spellID))
                    end
                end
            end
        end
    end
}

-- On target changed
function CCChainAssist:OnTargetChanged()
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Check if new target exists
    if UnitExists("target") then
        local targetGUID = UnitGUID("target")
        
        -- Check if target is under CC
        if activeCCs[targetGUID] then
            -- Show CC status if configured
            if settings.visualSettings.showCCDuration then
                for _, ccInfo in pairs(activeCCs[targetGUID]) do
                    local remaining = ccInfo.endTime - GetTime()
                    if remaining > 0 then
                        API.PrintDebug(UnitName("target") .. " is under " .. ccInfo.spellName .. " for " .. string.format("%.1f", remaining) .. " seconds")
                    end
                end
            end
            
            -- Show DR status if configured
            if settings.visualSettings.showDRStatus then
                self:ShowTargetDRStatus(targetGUID)
            end
        end
        
        -- Check if target is a potential CC target
        if UnitCanAttack("player", "target") and not UnitIsDead("target") then
            -- Show suggested CCs for this target
            self:SuggestCCsForTarget("target")
        end
    end
}

-- On focus changed
function CCChainAssist:OnFocusChanged()
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Check if new focus exists
    if UnitExists("focus") then
        local focusGUID = UnitGUID("focus")
        
        -- Check if focus is under CC
        if activeCCs[focusGUID] then
            -- Show CC status if configured
            if settings.visualSettings.showCCDuration then
                for _, ccInfo in pairs(activeCCs[focusGUID]) do
                    local remaining = ccInfo.endTime - GetTime()
                    if remaining > 0 then
                        API.PrintDebug(UnitName("focus") .. " is under " .. ccInfo.spellName .. " for " .. string.format("%.1f", remaining) .. " seconds")
                    end
                end
            end
            
            -- Show DR status if configured
            if settings.visualSettings.showDRStatus then
                self:ShowTargetDRStatus(focusGUID)
            end
        end
    end
}

-- On player entering world
function CCChainAssist:OnPlayerEnteringWorld()
    -- Reset all CC and DR tracking
    activeCCs = {}
    pendingCCs = {}
    ccDiminishingReturns = {}
    ccImmunityDuration = {}
    
    -- Check instance type
    local inInstance, instanceType = IsInInstance()
    self.instanceType = instanceType
    
    -- Update settings
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    ccTrackingInterval = settings.generalSettings.ccTrackingInterval
    
    -- Start the monitor frame
    ccMonitorFrame:Show()
}

-- On zone changed
function CCChainAssist:OnZoneChanged()
    -- Check instance type
    local inInstance, instanceType = IsInInstance()
    self.instanceType = instanceType
    
    -- Reset all CC and DR tracking
    activeCCs = {}
    pendingCCs = {}
    ccDiminishingReturns = {}
    ccImmunityDuration = {}
}

-- On arena prep
function CCChainAssist:OnArenaPrep()
    -- Reset all CC and DR tracking
    activeCCs = {}
    pendingCCs = {}
    ccDiminishingReturns = {}
    ccImmunityDuration = {}
    
    -- This is a good time to plan CC chains if in arena
    if PvPManager then
        local opponents = PvPManager:GetArenaOpponents()
        
        if opponents and #opponents > 0 then
            self:PlanArenaOpening(opponents)
        end
    end
}

-- On arena opponent update
function CCChainAssist:OnArenaOpponentUpdate(unit, updateReason)
    -- If an opponent becomes visible, we might want to update our CC plans
    if updateReason == "seen" then
        -- Check if this is a valid arena opponent
        if UnitExists(unit) and UnitIsEnemy("player", unit) then
            -- Update CC targets
            self:EvaluateCCTarget(unit)
        end
    end
}

-- On group roster update
function CCChainAssist:OnGroupRosterUpdate()
    -- Skip if party coordination is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enablePartyCoordination then
        return
    end
    
    -- Update party chain assignments
    self:UpdatePartyChainAssignments()
}

-- On party member disable
function CCChainAssist:OnPartyMemberDisable(unit)
    -- Check if this is a party member
    if UnitInParty(unit) then
        -- Get unit GUID
        local unitGUID = UnitGUID(unit)
        
        -- Check if this unit had chain assignments
        if partyChainAssignments[unitGUID] then
            -- Reassign chains
            self:ReassignChainAssignments(unitGUID)
        end
    end
}

-- On party member enable
function CCChainAssist:OnPartyMemberEnable(unit)
    -- Check if this is a party member
    if UnitInParty(unit) then
        -- Update party chain assignments
        self:UpdatePartyChainAssignments()
    end
}

-- Monitor CCs
function CCChainAssist:MonitorCCs()
    -- Skip if CC Chain Assist is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.enableCCChainAssist or not isEnabled then
        return
    end
    
    -- Get current time
    local now = GetTime()
    
    -- Update last check time
    lastCCCheck = now
    
    -- Check each active CC
    for targetGUID, targetCCs in pairs(activeCCs) do
        for spellID, ccInfo in pairs(targetCCs) do
            -- Check if CC has expired
            if now > ccInfo.endTime then
                -- CC has expired, remove it
                activeCCs[targetGUID][spellID] = nil
                
                -- If this was the last CC on the target, remove the target entry
                if not next(activeCCs[targetGUID]) then
                    activeCCs[targetGUID] = nil
                end
                
                -- If the source was the player, handle expiry
                if ccInfo.sourceGUID == UnitGUID("player") then
                    -- Check if this was part of a chain
                    if isInChain and currentChainTarget == targetGUID then
                        -- Handle next CC in chain
                        self:HandleNextCCInChain(targetGUID)
                    end
                end
            elseif ccInfo.endTime - now < 1.0 and not ccInfo.warningIssued then
                -- CC is about to expire, show warning
                ccInfo.warningIssued = true
                
                -- Play alert sound if configured
                if settings.visualSettings.ccAlertSound then
                    PlaySound(SOUNDKIT.READY_CHECK_WAITING)
                end
                
                -- Show alert to player
                if ccInfo.sourceGUID == UnitGUID("player") then
                    API.PrintMessage(ccInfo.spellName .. " on " .. ccInfo.destName .. " ending in 1 second")
                end
            end
        end
    end
    
    -- Check for CC immunity expirations
    for targetGUID, categories in pairs(ccImmunityDuration) do
        for category, expiryTime in pairs(categories) do
            if now > expiryTime then
                -- Immunity has expired, remove it
                ccImmunityDuration[targetGUID][category] = nil
            end
        end
        
        -- Remove empty entries
        if not next(ccImmunityDuration[targetGUID]) then
            ccImmunityDuration[targetGUID] = nil
        end
    end
    
    -- Check for DR resets
    for targetGUID, categories in pairs(ccDiminishingReturns) do
        for category, drInfo in pairs(categories) do
            if now > drInfo.resetTime then
                -- DR has reset, remove it
                ccDiminishingReturns[targetGUID][category] = nil
            end
        end
        
        -- Remove empty entries
        if not next(ccDiminishingReturns[targetGUID]) then
            ccDiminishingReturns[targetGUID] = nil
        end
    end
    
    -- Check for chain timeout
    if isInChain and currentChainTarget then
        -- If no CC has been applied in the last 5 seconds, consider the chain broken
        local lastCC = self:GetLastCCOnTarget(currentChainTarget)
        
        if not lastCC or now - lastCC.endTime > 5.0 then
            -- Chain has timed out
            isInChain = false
            currentChainTarget = nil
            API.PrintDebug("CC chain has timed out")
        end
    end
}

-- Get CC info
function CCChainAssist:GetCCInfo(spellID)
    -- First check player's own CC spells
    for _, ccSpell in ipairs(playerCCs) do
        if ccSpell.spellID == spellID then
            return ccSpell.type, ccSpell.duration, ccSpell.drCategory
        end
    end
    
    -- Check known CC spells from all classes
    local knownCCs = {
        -- A small selection of common CC spells from all classes
        -- In a real addon, this would be a much more comprehensive list
        
        -- Mage
        [118] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph
        [61305] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Black Cat
        [28272] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Pig
        [61721] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Rabbit
        [61780] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Turkey
        [28271] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Turtle
        [126819] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Porcupine
        [161354] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Monkey
        [161355] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Penguin
        [161372] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Peacock
        [277787] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Direhorn
        [277792] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Polymorph: Bumblebee
        [82691] = {type = CC_TYPE_INCAPACITATE, duration = 10, drCategory = DR_INCAPACITATE}, -- Ring of Frost
        [31661] = {type = CC_TYPE_DISORIENT, duration = 4, drCategory = DR_DISORIENT}, -- Dragon's Breath
        [122] = {type = CC_TYPE_ROOT, duration = 8, drCategory = DR_ROOT}, -- Frost Nova
        [33395] = {type = CC_TYPE_ROOT, duration = 8, drCategory = DR_ROOT}, -- Freeze (Water Elemental)
        [157997] = {type = CC_TYPE_ROOT, duration = 2, drCategory = DR_ROOT}, -- Ice Nova
        [2139] = {type = CC_TYPE_SILENCE, duration = 6, drCategory = DR_SILENCE}, -- Counterspell
        
        -- Paladin
        [853] = {type = CC_TYPE_STUN, duration = 6, drCategory = DR_STUN}, -- Hammer of Justice
        [105421] = {type = CC_TYPE_DISORIENT, duration = 6, drCategory = DR_DISORIENT}, -- Blinding Light
        [20066] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Repentance
        [10326] = {type = CC_TYPE_FEAR, duration = 40, drCategory = DR_FEAR}, -- Turn Evil
        [31935] = {type = CC_TYPE_SILENCE, duration = 3, drCategory = DR_SILENCE}, -- Avenger's Shield
        [217824] = {type = CC_TYPE_STUN, duration = 6, drCategory = DR_STUN}, -- Shield of Virtue
        
        -- Priest
        [605] = {type = CC_TYPE_INCAPACITATE, duration = 30, drCategory = DR_INCAPACITATE}, -- Mind Control
        [8122] = {type = CC_TYPE_FEAR, duration = 8, drCategory = DR_FEAR}, -- Psychic Scream
        [15487] = {type = CC_TYPE_SILENCE, duration = 5, drCategory = DR_SILENCE}, -- Silence
        [64044] = {type = CC_TYPE_FEAR, duration = 4, drCategory = DR_FEAR}, -- Psychic Horror
        [205369] = {type = CC_TYPE_DISORIENT, duration = 4, drCategory = DR_DISORIENT}, -- Mind Bomb
        [9484] = {type = CC_TYPE_INCAPACITATE, duration = 50, drCategory = DR_INCAPACITATE}, -- Shackle Undead
        [200196] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Holy Word: Chastise
        [200200] = {type = CC_TYPE_INCAPACITATE, duration = 4, drCategory = DR_INCAPACITATE}, -- Holy Word: Chastise (Talent)
        
        -- Rogue
        [6770] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Sap
        [2094] = {type = CC_TYPE_INCAPACITATE, duration = 8, drCategory = DR_INCAPACITATE}, -- Blind
        [1833] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Cheap Shot
        [408] = {type = CC_TYPE_STUN, duration = 6, drCategory = DR_STUN}, -- Kidney Shot
        [1776] = {type = CC_TYPE_INCAPACITATE, duration = 4, drCategory = DR_INCAPACITATE}, -- Gouge
        [1330] = {type = CC_TYPE_SILENCE, duration = 3, drCategory = DR_SILENCE}, -- Garrote - Silence
        [199743] = {type = CC_TYPE_STUN, duration = 2, drCategory = DR_STUN}, -- Parley
        
        -- Warlock
        [5782] = {type = CC_TYPE_FEAR, duration = 20, drCategory = DR_FEAR}, -- Fear
        [6789] = {type = CC_TYPE_FEAR, duration = 3, drCategory = DR_FEAR}, -- Mortal Coil
        [5484] = {type = CC_TYPE_FEAR, duration = 8, drCategory = DR_FEAR}, -- Howl of Terror
        [710] = {type = CC_TYPE_INCAPACITATE, duration = 30, drCategory = DR_INCAPACITATE}, -- Banish
        [6358] = {type = CC_TYPE_INCAPACITATE, duration = 30, drCategory = DR_INCAPACITATE}, -- Seduction (Succubus)
        [115268] = {type = CC_TYPE_INCAPACITATE, duration = 30, drCategory = DR_INCAPACITATE}, -- Mesmerize
        [22703] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Infernal Awakening
        [30283] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Shadowfury
        [118699] = {type = CC_TYPE_FEAR, duration = 8, drCategory = DR_FEAR}, -- Fear (Metamorphosis)
        
        -- Warrior
        [5246] = {type = CC_TYPE_FEAR, duration = 8, drCategory = DR_FEAR}, -- Intimidating Shout
        [132169] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Storm Bolt
        [107570] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Storm Bolt
        [46968] = {type = CC_TYPE_STUN, duration = 2, drCategory = DR_STUN}, -- Shockwave
        [236077] = {type = CC_TYPE_DISORIENT, duration = 4, drCategory = DR_DISORIENT}, -- Disarm
        [197690] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Defensive Stance Taunt
        
        -- Druid
        [339] = {type = CC_TYPE_ROOT, duration = 30, drCategory = DR_ROOT}, -- Entangling Roots
        [2637] = {type = CC_TYPE_INCAPACITATE, duration = 40, drCategory = DR_INCAPACITATE}, -- Hibernate
        [33786] = {type = CC_TYPE_INCAPACITATE, duration = 6, drCategory = DR_INCAPACITATE}, -- Cyclone
        [5211] = {type = CC_TYPE_STUN, duration = 5, drCategory = DR_STUN}, -- Mighty Bash
        [102359] = {type = CC_TYPE_ROOT, duration = 30, drCategory = DR_ROOT}, -- Mass Entanglement
        [99] = {type = CC_TYPE_INCAPACITATE, duration = 3, drCategory = DR_INCAPACITATE}, -- Incapacitating Roar
        [2908] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Soothe Animal
        [209753] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Cyclone
        [163505] = {type = CC_TYPE_STUN, duration = 1, drCategory = DR_STUN}, -- Rake
        
        -- Hunter
        [3355] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Freezing Trap
        [19386] = {type = CC_TYPE_INCAPACITATE, duration = 30, drCategory = DR_INCAPACITATE}, -- Wyvern Sting
        [5116] = {type = CC_TYPE_ROOT, duration = 6, drCategory = DR_ROOT}, -- Concussive Shot
        [19577] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Intimidation
        [24394] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Intimidation
        [117526] = {type = CC_TYPE_ROOT, duration = 20, drCategory = DR_ROOT}, -- Binding Shot
        [162480] = {type = CC_TYPE_ROOT, duration = 12, drCategory = DR_ROOT}, -- Steel Trap
        [187650] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Freezing Trap (PvP)
        
        -- Shaman
        [51514] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex
        [210873] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Compy)
        [211004] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Spider)
        [211010] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Snake)
        [211015] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Cockroach)
        [269352] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Skeletal Hatchling)
        [277778] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Zandalari Tendonripper)
        [277784] = {type = CC_TYPE_INCAPACITATE, duration = 60, drCategory = DR_INCAPACITATE}, -- Hex (Wicker Mongrel)
        [118905] = {type = CC_TYPE_STUN, duration = 5, drCategory = DR_STUN}, -- Static Charge
        [77505] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Earthquake (Stun)
        [118345] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Pulverize
        [204437] = {type = CC_TYPE_ROOT, duration = 8, drCategory = DR_ROOT}, -- Lightning Lasso
        
        -- Monk
        [115078] = {type = CC_TYPE_INCAPACITATE, duration = 50, drCategory = DR_INCAPACITATE}, -- Paralysis
        [107079] = {type = CC_TYPE_STUN, duration = 5, drCategory = DR_STUN}, -- Quaking Palm (Racial)
        [116706] = {type = CC_TYPE_ROOT, duration = 8, drCategory = DR_ROOT}, -- Disable
        [116705] = {type = CC_TYPE_ROOT, duration = 8, drCategory = DR_ROOT}, -- Spear Hand Strike
        [119381] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Leg Sweep
        [122470] = {type = CC_TYPE_INCAPACITATE, duration = 3, drCategory = DR_INCAPACITATE}, -- Touch of Karma
        [198909] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Song of Chi-Ji
        [202274] = {type = CC_TYPE_DISORIENT, duration = 3, drCategory = DR_DISORIENT}, -- Incendiary Brew
        
        -- Demon Hunter
        [217832] = {type = CC_TYPE_INCAPACITATE, duration = 4, drCategory = DR_INCAPACITATE}, -- Imprison
        [211881] = {type = CC_TYPE_INCAPACITATE, duration = 4, drCategory = DR_INCAPACITATE}, -- Fel Eruption
        [200166] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Metamorphosis
        [198813] = {type = CC_TYPE_STUN, duration = 2, drCategory = DR_STUN}, -- Vengeful Retreat
        [207685] = {type = CC_TYPE_DISORIENT, duration = 5, drCategory = DR_DISORIENT}, -- Sigil of Misery
        [204490] = {type = CC_TYPE_SILENCE, duration = 6, drCategory = DR_SILENCE}, -- Sigil of Silence
        [179057] = {type = CC_TYPE_STUN, duration = 2, drCategory = DR_STUN}, -- Chaos Nova
        [205630] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Illidan's Grasp
        
        -- Death Knight
        [47476] = {type = CC_TYPE_SILENCE, duration = 5, drCategory = DR_SILENCE}, -- Strangulate
        [91800] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Gnaw (Ghoul)
        [91797] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Monstrous Blow (Mutated Ghoul)
        [108194] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Asphyxiate
        [221562] = {type = CC_TYPE_STUN, duration = 5, drCategory = DR_STUN}, -- Asphyxiate (Blood)
        [207167] = {type = CC_TYPE_DISORIENT, duration = 4, drCategory = DR_DISORIENT}, -- Blinding Sleet
        [207171] = {type = CC_TYPE_DISORIENT, duration = 5, drCategory = DR_DISORIENT}, -- Winter is Coming
        [212540] = {type = CC_TYPE_ROOT, duration = 8, drCategory = DR_ROOT}, -- Flesh Hook
        
        -- Evoker
        [355689] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Landslide
        [370665] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Rescue
        [360806] = {type = CC_TYPE_DISORIENT, duration = 2, drCategory = DR_DISORIENT}, -- Sleep Walk
        [372245] = {type = CC_TYPE_STUN, duration = 4, drCategory = DR_STUN}, -- Terror of the Skies
        [406732] = {type = CC_TYPE_STUN, duration = 3, drCategory = DR_STUN}, -- Spatial Paradox
    }
    
    -- Check if the spell is in our known CC list
    if knownCCs[spellID] then
        return knownCCs[spellID].type, knownCCs[spellID].duration, knownCCs[spellID].drCategory
    end
    
    -- If we get here, the spell is not a known CC
    return nil
end

-- Can CC be broken by damage
function CCChainAssist:CanCCBeBreakByDamage(ccType)
    -- Some CC types are broken by damage
    if ccType == CC_TYPE_INCAPACITATE or ccType == CC_TYPE_FEAR or ccType == CC_TYPE_DISORIENT then
        return true
    end
    
    return false
end

-- Get DR factor
function CCChainAssist:GetDRFactor(unitGUID, drCategory)
    -- If no DR category, no reduction
    if not drCategory or drCategory == DR_NONE then
        return 1.0
    end
    
    -- Check if we're tracking DR for this unit and category
    if not ccDiminishingReturns[unitGUID] or not ccDiminishingReturns[unitGUID][drCategory] then
        return 1.0
    end
    
    -- Get DR info
    local drInfo = ccDiminishingReturns[unitGUID][drCategory]
    
    -- Check if we've hit the DR cap
    if drInfo.applications >= 4 then
        return 0.0 -- Immune
    end
    
    -- Return the appropriate reduction factor
    if drInfo.applications == 1 then
        return 1.0 -- Full duration
    elseif drInfo.applications == 2 then
        return DR_REDUCTION_FIRST -- 50% duration
    elseif drInfo.applications == 3 then
        return DR_REDUCTION_SECOND -- 25% duration
    end
    
    -- Shouldn't get here, but return 1.0 to be safe
    return 1.0
}

-- Update diminishing returns
function CCChainAssist:UpdateDiminishingReturns(unitGUID, drCategory)
    -- If no DR category, nothing to update
    if not drCategory or drCategory == DR_NONE then
        return
    end
    
    -- Get current time
    local now = GetTime()
    
    -- Initialize DR tracking for this unit if needed
    if not ccDiminishingReturns[unitGUID] then
        ccDiminishingReturns[unitGUID] = {}
    end
    
    -- Initialize DR tracking for this category if needed
    if not ccDiminishingReturns[unitGUID][drCategory] then
        ccDiminishingReturns[unitGUID][drCategory] = {
            applications = 0,
            lastApplied = 0,
            resetTime = 0
        }
    end
    
    -- Get DR info
    local drInfo = ccDiminishingReturns[unitGUID][drCategory]
    
    -- Check if DR has reset
    if drInfo.resetTime > 0 and now > drInfo.resetTime then
        -- DR has reset, start fresh
        drInfo.applications = 0
    end
    
    -- Increment application count (capped at 4)
    drInfo.applications = math.min(drInfo.applications + 1, 4)
    drInfo.lastApplied = now
    drInfo.resetTime = now + DR_RESET_TIMER
    
    -- Update last DR update time
    lastDRUpdate[unitGUID] = now
    
    -- Debug output
    API.PrintDebug("DR updated for " .. drCategory .. " on " .. unitGUID .. ": " .. drInfo.applications .. " applications")
}

-- Is target immune to CC
function CCChainAssist:IsTargetImmuneToCC(unitGUID, drCategory, ccType)
    -- Check DR immunity
    if drCategory and drCategory ~= DR_NONE then
        -- Check if we're tracking DR for this unit and category
        if ccDiminishingReturns[unitGUID] and ccDiminishingReturns[unitGUID][drCategory] then
            -- Get DR info
            local drInfo = ccDiminishingReturns[unitGUID][drCategory]
            
            -- Check if we've hit the DR cap
            if drInfo.applications >= 4 then
                return true -- Immune due to DR
            end
        end
        
        -- Check for temporary CC immunity
        if ccImmunityDuration[unitGUID] and ccImmunityDuration[unitGUID][drCategory] then
            if GetTime() < ccImmunityDuration[unitGUID][drCategory] then
                return true -- Temporary immunity
            end
        end
    end
    
    -- Check for target's specific CC immunities (e.g., Bladestorm)
    if targetCCImmunities[unitGUID] then
        if targetCCImmunities[unitGUID][ccType] then
            return true -- Immune to this CC type
        end
    end
    
    return false
}

-- Handle CC chain coordination
function CCChainAssist:HandleCCChainCoordination(targetGUID, ccInfo)
    -- Skip if not in a chain or this is a different target
    if not isInChain or currentChainTarget ~= targetGUID then
        -- This might be the start of a new chain
        isInChain = true
        currentChainTarget = targetGUID
        
        -- Add to chain
        if not ccChains[targetGUID] then
            ccChains[targetGUID] = {}
        end
        
        table.insert(ccChains[targetGUID], ccInfo)
        
        -- Debug output
        API.PrintDebug("Starting new CC chain on " .. ccInfo.destName)
        
        -- Notify party of CC chain start if configured
        local settings = ConfigRegistry:GetSettings("CCChainAssist")
        if settings.communicationSettings.announceCC and settings.communicationSettings.announceNextCC then
            -- Determine the next CC type to use
            local nextCCType = self:DetermineNextCCType(targetGUID, ccInfo.ccType)
            
            -- Find a party member who can cast this type of CC
            local nextCCer = self:FindPartyCCer(nextCCType)
            
            if nextCCer then
                -- Announce next CC
                self:AnnounceNextCC(ccInfo.destName, nextCCType, nextCCer)
            end
        end
    else
        -- This is part of an existing chain
        table.insert(ccChains[targetGUID], ccInfo)
        
        -- Debug output
        API.PrintDebug("Adding to CC chain on " .. ccInfo.destName)
    end
}

-- Handle next CC in chain
function CCChainAssist:HandleNextCCInChain(targetGUID)
    -- Skip if no smart chaining
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.generalSettings.smartChaining then
        return
    end
    
    -- Skip if not in a chain or this is a different target
    if not isInChain or currentChainTarget ~= targetGUID then
        return
    end
    
    -- Get the last CC used in this chain
    local lastCC = self:GetLastCCOnTarget(targetGUID)
    
    if not lastCC then
        return
    end
    
    -- Determine the next CC type to use
    local nextCCType = self:DetermineNextCCType(targetGUID, lastCC.ccType)
    
    -- Check if player has a suitable CC of this type
    local playerCC = self:GetBestPlayerCC(nextCCType, targetGUID)
    
    if playerCC then
        -- Suggest using this CC
        API.PrintMessage("Suggest using " .. playerCC.name .. " next on " .. lastCC.destName)
    else
        -- Player doesn't have a suitable CC
        -- Check if a party member does
        if settings.generalSettings.enablePartyCoordination then
            -- Find a party member who can cast this type of CC
            local nextCCer = self:FindPartyCCer(nextCCType)
            
            if nextCCer then
                -- Announce next CC
                self:AnnounceNextCC(lastCC.destName, nextCCType, nextCCer)
            end
        end
    end
}

-- Determine next CC type
function CCChainAssist:DetermineNextCCType(targetGUID, lastCCType)
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    
    -- Default chain: Stun -> Fear -> Incapacitate -> Root
    local ccChainOrder = {
        [CC_TYPE_STUN] = settings.ccChainSettings.fearSecond and CC_TYPE_FEAR or CC_TYPE_INCAPACITATE,
        [CC_TYPE_FEAR] = settings.ccChainSettings.incapacitateThird and CC_TYPE_INCAPACITATE or CC_TYPE_ROOT,
        [CC_TYPE_INCAPACITATE] = settings.ccChainSettings.rootFourth and CC_TYPE_ROOT or CC_TYPE_STUN,
        [CC_TYPE_ROOT] = settings.ccChainSettings.stunFirst and CC_TYPE_STUN or CC_TYPE_FEAR,
        [CC_TYPE_SILENCE] = settings.ccChainSettings.stunFirst and CC_TYPE_STUN or CC_TYPE_FEAR,
        [CC_TYPE_DISARM] = settings.ccChainSettings.stunFirst and CC_TYPE_STUN or CC_TYPE_FEAR
    }
    
    -- Handle special case for target role
    local targetRole = self:GetTargetRole(targetGUID)
    if targetRole == "HEALER" and settings.ccChainSettings.silenceHealer then
        return CC_TYPE_SILENCE
    elseif targetRole == "DAMAGER" and settings.ccChainSettings.disarmDamageDealer then
        return CC_TYPE_DISARM
    end
    
    -- Use the next type in chain
    return ccChainOrder[lastCCType] or CC_TYPE_STUN
}

-- Get target role
function CCChainAssist:GetTargetRole(targetGUID)
    -- Check if this is a player
    local unit = self:GetUnitFromGUID(targetGUID)
    if unit and UnitIsPlayer(unit) then
        -- Check for role from PvP system
        if PvPManager then
            return PvPManager:GetEnemyRole(unit) or "DAMAGER"
        end
        
        -- Fallback to class-based guess
        local _, class = UnitClass(unit)
        if class == "PRIEST" or class == "DRUID" or class == "MONK" or class == "PALADIN" or class == "SHAMAN" or class == "EVOKER" then
            return "HEALER"
        elseif class == "WARRIOR" or class == "DEATHKNIGHT" or class == "DEMONHUNTER" then
            return "TANK"
        else
            return "DAMAGER"
        end
    end
    
    -- Default to damager for NPCs
    return "DAMAGER"
}

-- Get best player CC
function CCChainAssist:GetBestPlayerCC(ccType, targetGUID)
    local bestCC = nil
    local bestPriority = 0
    
    -- Check each player CC
    for _, ccSpell in ipairs(playerCCs) do
        -- Match requested CC type
        if ccSpell.type == ccType then
            -- Skip if on cooldown
            if self:IsSpellOnCooldown(ccSpell.spellID) then
                goto continue
            end
            
            -- Skip if target is immune to this DR category
            if self:IsTargetImmuneToCC(targetGUID, ccSpell.drCategory, ccType) then
                goto continue
            end
            
            -- Skip if target doesn't match allowed target types
            if ccSpell.targetTypes and not self:DoesTargetMatchTypes(targetGUID, ccSpell.targetTypes) then
                goto continue
            end
            
            -- Skip if requires stealth and player is not stealthed
            if ccSpell.stealth and not IsStealthed() then
                goto continue
            end
            
            -- Check priority
            if ccSpell.priority > bestPriority then
                bestPriority = ccSpell.priority
                bestCC = ccSpell
            end
        end
        
        ::continue::
    end
    
    return bestCC
}

-- Is spell on cooldown
function CCChainAssist:IsSpellOnCooldown(spellID)
    local start, duration = GetSpellCooldown(spellID)
    
    if start > 0 and duration > 0 then
        local remaining = start + duration - GetTime()
        return remaining > 0
    end
    
    return false
end

-- Does target match types
function CCChainAssist:DoesTargetMatchTypes(targetGUID, targetTypes)
    -- Get unit from GUID
    local unit = self:GetUnitFromGUID(targetGUID)
    if not unit then
        return false
    end
    
    -- Check creature type
    local creatureType = UnitCreatureType(unit)
    
    -- No type restrictions if player
    if UnitIsPlayer(unit) then
        return true
    end
    
    -- Check against allowed types
    for _, allowedType in ipairs(targetTypes) do
        if string.lower(creatureType) == string.lower(allowedType) then
            return true
        end
    end
    
    return false
}

-- Get unit from GUID
function CCChainAssist:GetUnitFromGUID(guid)
    -- Check common unit tokens
    if UnitExists("target") and UnitGUID("target") == guid then
        return "target"
    elseif UnitExists("focus") and UnitGUID("focus") == guid then
        return "focus"
    elseif UnitExists("mouseover") and UnitGUID("mouseover") == guid then
        return "mouseover"
    elseif UnitExists("pet") and UnitGUID("pet") == guid then
        return "pet"
    end
    
    -- Check raid targets
    for i = 1, 8 do
        local unit = "raid" .. i .. "target"
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    
    -- Check party targets
    for i = 1, 4 do
        local unit = "party" .. i .. "target"
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
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
}

-- Get last CC on target
function CCChainAssist:GetLastCCOnTarget(targetGUID)
    -- Check CC chains
    if ccChains[targetGUID] and #ccChains[targetGUID] > 0 then
        return ccChains[targetGUID][#ccChains[targetGUID]]
    end
    
    return nil
}

-- Update chain status
function CCChainAssist:UpdateChainStatus(targetGUID, spellID)
    -- Skip if not in a chain or this is a different target
    if not isInChain or currentChainTarget ~= targetGUID then
        return
    end
    
    -- Update chain lock
    chainLock[targetGUID] = GetTime() + ccGlobalCooldown
}

-- Plan arena opening
function CCChainAssist:PlanArenaOpening(opponents)
    -- Skip if no opponents
    if not opponents or #opponents == 0 then
        return
    end
    
    -- Reset CC targets
    ccTargets = {}
    
    -- Evaluate each opponent
    for _, opponent in ipairs(opponents) do
        self:EvaluateCCTarget(opponent.unit, opponent.class, opponent.spec)
    end
    
    -- Sort targets by priority
    table.sort(ccTargets, function(a, b) return a.priority > b.priority end)
    
    -- Announce plan if configured
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if settings.communicationSettings.announceCC and #ccTargets > 0 then
        -- Find the highest priority target
        local target = ccTargets[1]
        
        -- Determine CC to use
        local ccType = settings.ccChainSettings.stunFirst and CC_TYPE_STUN or CC_TYPE_INCAPACITATE
        local ccSpell = self:GetBestPlayerCC(ccType, target.destGUID)
        
        if ccSpell then
            API.PrintMessage("Arena opening plan: " .. ccSpell.name .. " on " .. target.destName)
        end
    end
}

-- Evaluate CC target
function CCChainAssist:EvaluateCCTarget(unit, class, spec)
    -- Skip if unit doesn't exist
    if not UnitExists(unit) then
        return
    end
    
    -- Get unit info
    local unitGUID = UnitGUID(unit)
    local unitName = UnitName(unit)
    
    -- Skip if already in list
    for _, target in ipairs(ccTargets) do
        if target.destGUID == unitGUID then
            return
        end
    end
    
    -- Determine priority
    local priority = 5 -- Default priority
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    
    -- Determine unit role if it's a player
    if UnitIsPlayer(unit) then
        -- Get class if not provided
        if not class then
            _, class = UnitClass(unit)
        end
        
        -- Get role
        local role = "DAMAGER"
        if class == "PRIEST" or class == "DRUID" or class == "MONK" or class == "PALADIN" or class == "SHAMAN" or class == "EVOKER" then
            -- These classes can be healers, check spec
            if PvPManager and PvPManager:IsHealerSpec(class, spec) then
                role = "HEALER"
            end
        elseif class == "WARRIOR" or class == "DEATHKNIGHT" or class == "DEMONHUNTER" then
            -- These classes can be tanks, check spec
            if PvPManager and PvPManager:IsTankSpec(class, spec) then
                role = "TANK"
            end
        end
        
        -- Set priority based on role
        if role == "HEALER" then
            priority = settings.ccPrioritySettings.priorityHealer
        elseif role == "DAMAGER" then
            priority = settings.ccPrioritySettings.priorityDamage
        elseif role == "TANK" then
            priority = settings.ccPrioritySettings.priorityTank
        end
        
        -- Adjust priority based on class
        if class == "DRUID" then
            priority = priority * settings.ccPrioritySettings.priorityDruid / 5
        elseif class == "ROGUE" then
            priority = priority * settings.ccPrioritySettings.priorityRogue / 5
        elseif class == "SHAMAN" then
            priority = priority * settings.ccPrioritySettings.priorityShaman / 5
        end
    else
        -- For NPCs, use classification
        local classification = UnitClassification(unit)
        if classification == "worldboss" or classification == "rareelite" then
            priority = 10
        elseif classification == "elite" then
            priority = 8
        elseif classification == "rare" then
            priority = 7
        end
    end
    
    -- Add to CC targets
    table.insert(ccTargets, {
        destGUID = unitGUID,
        destName = unitName,
        unit = unit,
        priority = priority,
        class = class,
        spec = spec
    })
}

-- Find party CCer
function CCChainAssist:FindPartyCCer(ccType)
    -- Skip if not in party
    if not IsInGroup() then
        return nil
    end
    
    -- Check each party member
    for i = 1, GetNumGroupMembers() do
        local unit = "party" .. i
        
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            -- Check if this player can cast the requested CC type
            local canCastType = self:CanUnitCastCCType(unit, ccType)
            
            if canCastType then
                return UnitName(unit)
            end
        end
    end
    
    return nil
}

-- Can unit cast CC type
function CCChainAssist:CanUnitCastCCType(unit, ccType)
    -- Get unit's class
    local _, class = UnitClass(unit)
    
    -- Map classes to CC types they can provide
    local classCCTypes = {
        ["MAGE"] = {
            [CC_TYPE_INCAPACITATE] = true, -- Polymorph
            [CC_TYPE_ROOT] = true, -- Frost Nova
            [CC_TYPE_DISORIENT] = true, -- Dragon's Breath
            [CC_TYPE_SILENCE] = true -- Counterspell
        },
        ["PALADIN"] = {
            [CC_TYPE_STUN] = true, -- Hammer of Justice
            [CC_TYPE_INCAPACITATE] = true, -- Repentance
            [CC_TYPE_DISORIENT] = true -- Blinding Light
        },
        ["WARRIOR"] = {
            [CC_TYPE_STUN] = true, -- Storm Bolt
            [CC_TYPE_FEAR] = true -- Intimidating Shout
        },
        ["PRIEST"] = {
            [CC_TYPE_FEAR] = true, -- Psychic Scream
            [CC_TYPE_INCAPACITATE] = true, -- Mind Control
            [CC_TYPE_SILENCE] = true -- Silence
        },
        ["ROGUE"] = {
            [CC_TYPE_STUN] = true, -- Kidney Shot
            [CC_TYPE_INCAPACITATE] = true -- Sap, Blind, Gouge
        },
        ["WARLOCK"] = {
            [CC_TYPE_FEAR] = true, -- Fear
            [CC_TYPE_INCAPACITATE] = true, -- Banish, Seduction
            [CC_TYPE_STUN] = true -- Shadowfury
        },
        ["DRUID"] = {
            [CC_TYPE_ROOT] = true, -- Entangling Roots
            [CC_TYPE_INCAPACITATE] = true, -- Hibernate, Cyclone
            [CC_TYPE_STUN] = true -- Mighty Bash
        },
        ["HUNTER"] = {
            [CC_TYPE_INCAPACITATE] = true, -- Freezing Trap
            [CC_TYPE_STUN] = true, -- Intimidation
            [CC_TYPE_ROOT] = true -- Concussive Shot, Binding Shot
        },
        ["SHAMAN"] = {
            [CC_TYPE_INCAPACITATE] = true, -- Hex
            [CC_TYPE_STUN] = true -- Capacitor Totem
        },
        ["MONK"] = {
            [CC_TYPE_INCAPACITATE] = true, -- Paralysis
            [CC_TYPE_STUN] = true -- Leg Sweep
        },
        ["DEMONHUNTER"] = {
            [CC_TYPE_INCAPACITATE] = true, -- Imprison
            [CC_TYPE_STUN] = true -- Chaos Nova
        },
        ["DEATHKNIGHT"] = {
            [CC_TYPE_STUN] = true, -- Asphyxiate
            [CC_TYPE_SILENCE] = true -- Strangulate
        },
        ["EVOKER"] = {
            [CC_TYPE_STUN] = true, -- Landslide
            [CC_TYPE_DISORIENT] = true -- Sleep Walk
        }
    }
    
    -- Check if class can cast this CC type
    if classCCTypes[class] and classCCTypes[class][ccType] then
        return true
    end
    
    return false
}

-- Update party chain assignments
function CCChainAssist:UpdatePartyChainAssignments()
    -- Skip if not in party or party coordination disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not IsInGroup() or not settings.generalSettings.enablePartyCoordination then
        return
    end
    
    -- Clear current assignments
    partyChainAssignments = {}
    
    -- Get available CC types for each party member
    local partyCCs = {}
    
    -- Add player
    partyCCs[UnitGUID("player")] = {
        name = UnitName("player"),
        class = select(2, UnitClass("player")),
        unit = "player",
        ccs = {}
    }
    
    -- Add player CCs
    for _, ccSpell in ipairs(playerCCs) do
        local ccInfo = {
            spellID = ccSpell.spellID,
            name = ccSpell.name,
            type = ccSpell.type,
            drCategory = ccSpell.drCategory,
            duration = ccSpell.duration,
            priority = ccSpell.priority,
            isMainCC = ccSpell.isMainCC
        }
        
        table.insert(partyCCs[UnitGUID("player")].ccs, ccInfo)
    end
    
    -- Check each party member
    for i = 1, GetNumGroupMembers() do
        local unit = "party" .. i
        
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            
            partyCCs[guid] = {
                name = name,
                class = class,
                unit = unit,
                ccs = {}
            }
            
            -- Determine CCs based on class
            self:GetClassCCs(class, partyCCs[guid].ccs)
        end
    end
    
    -- Now assign roles in CC chains
    -- For each CC type, assign the best party member
    local ccTypes = {CC_TYPE_STUN, CC_TYPE_INCAPACITATE, CC_TYPE_FEAR, CC_TYPE_ROOT, CC_TYPE_SILENCE, CC_TYPE_DISORIENT, CC_TYPE_DISARM}
    
    for _, ccType in ipairs(ccTypes) do
        -- Find best party member for this CC type
        local bestMember = nil
        local bestPriority = 0
        
        for guid, info in pairs(partyCCs) do
            -- Check if this member has this CC type
            for _, cc in ipairs(info.ccs) do
                if cc.type == ccType and (cc.isMainCC or not bestMember) and cc.priority > bestPriority then
                    bestMember = guid
                    bestPriority = cc.priority
                end
            end
        end
        
        -- Assign this CC type to the best member
        if bestMember then
            partyChainAssignments[ccType] = bestMember
        end
    end
}

-- Reassign chain assignments
function CCChainAssist:ReassignChainAssignments(deadMemberGUID)
    -- Skip if not in party or party coordination disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not IsInGroup() or not settings.generalSettings.enablePartyCoordination then
        return
    end
    
    -- Find CCs that need to be reassigned
    for ccType, assignedGUID in pairs(partyChainAssignments) do
        if assignedGUID == deadMemberGUID then
            partyChainAssignments[ccType] = nil
        end
    end
    
    -- Update party chain assignments to fill gaps
    self:UpdatePartyChainAssignments()
}

-- Get class CCs
function CCChainAssist:GetClassCCs(class, ccs)
    -- This simplified version just adds the main CC for each class
    if class == "MAGE" then
        table.insert(ccs, {
            spellID = 118,
            name = "Polymorph",
            type = CC_TYPE_INCAPACITATE,
            drCategory = DR_INCAPACITATE,
            duration = 60,
            priority = 8,
            isMainCC = true
        })
    elseif class == "PALADIN" then
        table.insert(ccs, {
            spellID = 853,
            name = "Hammer of Justice",
            type = CC_TYPE_STUN,
            drCategory = DR_STUN,
            duration = 6,
            priority = 8,
            isMainCC = true
        })
    elseif class == "WARRIOR" then
        table.insert(ccs, {
            spellID = 5246,
            name = "Intimidating Shout",
            type = CC_TYPE_FEAR,
            drCategory = DR_FEAR,
            duration = 8,
            priority = 7,
            isMainCC = true
        })
    elseif class == "PRIEST" then
        table.insert(ccs, {
            spellID = 8122,
            name = "Psychic Scream",
            type = CC_TYPE_FEAR,
            drCategory = DR_FEAR,
            duration = 8,
            priority = 7,
            isMainCC = true
        })
    elseif class == "ROGUE" then
        table.insert(ccs, {
            spellID = 6770,
            name = "Sap",
            type = CC_TYPE_INCAPACITATE,
            drCategory = DR_INCAPACITATE,
            duration = 60,
            priority = 9,
            isMainCC = true
        })
    elseif class == "WARLOCK" then
        table.insert(ccs, {
            spellID = 5782,
            name = "Fear",
            type = CC_TYPE_FEAR,
            drCategory = DR_FEAR,
            duration = 20,
            priority = 8,
            isMainCC = true
        })
    elseif class == "DRUID" then
        table.insert(ccs, {
            spellID = 339,
            name = "Entangling Roots",
            type = CC_TYPE_ROOT,
            drCategory = DR_ROOT,
            duration = 30,
            priority = 7,
            isMainCC = true
        })
    elseif class == "HUNTER" then
        table.insert(ccs, {
            spellID = 3355,
            name = "Freezing Trap",
            type = CC_TYPE_INCAPACITATE,
            drCategory = DR_INCAPACITATE,
            duration = 60,
            priority = 9,
            isMainCC = true
        })
    elseif class == "SHAMAN" then
        table.insert(ccs, {
            spellID = 51514,
            name = "Hex",
            type = CC_TYPE_INCAPACITATE,
            drCategory = DR_INCAPACITATE,
            duration = 60,
            priority = 8,
            isMainCC = true
        })
    elseif class == "MONK" then
        table.insert(ccs, {
            spellID = 115078,
            name = "Paralysis",
            type = CC_TYPE_INCAPACITATE,
            drCategory = DR_INCAPACITATE,
            duration = 50,
            priority = 9,
            isMainCC = true
        })
    elseif class == "DEMONHUNTER" then
        table.insert(ccs, {
            spellID = 217832,
            name = "Imprison",
            type = CC_TYPE_INCAPACITATE,
            drCategory = DR_INCAPACITATE,
            duration = 4,
            priority = 9,
            isMainCC = true
        })
    elseif class == "DEATHKNIGHT" then
        table.insert(ccs, {
            spellID = 108194,
            name = "Asphyxiate",
            type = CC_TYPE_STUN,
            drCategory = DR_STUN,
            duration = 4,
            priority = 8,
            isMainCC = true
        })
    elseif class == "EVOKER" then
        table.insert(ccs, {
            spellID = 360806,
            name = "Sleep Walk",
            type = CC_TYPE_DISORIENT,
            drCategory = DR_DISORIENT,
            duration = 2,
            priority = 7,
            isMainCC = true
        })
    end
}

-- Announce CC application
function CCChainAssist:AnnounceCCApplication(ccInfo)
    -- Skip if announcing is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.communicationSettings.announceCC then
        return
    end
    
    -- Only announce player's CCs
    if ccInfo.sourceGUID ~= UnitGUID("player") then
        return
    end
    
    -- Create message
    local message = "CC: " .. ccInfo.spellName .. " on " .. ccInfo.destName
    
    -- Add DR info if configured
    if settings.communicationSettings.announceDR and ccInfo.drCategory then
        local drFactor = self:GetDRFactor(ccInfo.destGUID, ccInfo.drCategory)
        if drFactor < 1.0 then
            message = message .. " (" .. math.floor(drFactor * 100) .. "% duration)"
        end
    end
    
    -- Send to appropriate channel
    local channel = settings.communicationSettings.announceCCChannel
    
    if channel == "Party" and IsInGroup() then
        SendChatMessage(message, "PARTY")
    elseif channel == "Raid" and IsInRaid() then
        SendChatMessage(message, "RAID")
    elseif channel == "Say" then
        SendChatMessage(message, "SAY")
    elseif channel == "Emote" then
        SendChatMessage(message, "EMOTE")
    else
        -- Just print to chat frame
        API.PrintMessage(message)
    end
}

-- Announce CC break
function CCChainAssist:AnnounceCCBreak(ccInfo)
    -- Skip if announcing is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.communicationSettings.announceCCBreak then
        return
    end
    
    -- Only announce player's CCs
    if ccInfo.sourceGUID ~= UnitGUID("player") then
        return
    end
    
    -- Create message
    local message = "CC BROKEN: " .. ccInfo.spellName .. " on " .. ccInfo.destName
    
    -- Add breaker info if available
    if ccInfo.breakerName then
        message = message .. " by " .. ccInfo.breakerName
        
        if ccInfo.breakSpellName then
            message = message .. "'s " .. ccInfo.breakSpellName
        end
    elseif ccInfo.breakType then
        message = message .. " (" .. ccInfo.breakType .. ")"
    end
    
    -- Send to appropriate channel
    local channel = settings.communicationSettings.announceCCChannel
    
    if channel == "Party" and IsInGroup() then
        SendChatMessage(message, "PARTY")
    elseif channel == "Raid" and IsInRaid() then
        SendChatMessage(message, "RAID")
    elseif channel == "Say" then
        SendChatMessage(message, "SAY")
    elseif channel == "Emote" then
        SendChatMessage(message, "EMOTE")
    else
        -- Just print to chat frame
        API.PrintMessage(message)
    end
}

-- Announce next CC
function CCChainAssist:AnnounceNextCC(targetName, ccType, ccerName)
    -- Skip if announcing is disabled
    local settings = ConfigRegistry:GetSettings("CCChainAssist")
    if not settings.communicationSettings.announceNextCC then
        return
    end
    
    -- Create message
    local message = "NEXT CC: Need " .. self:GetCCTypeName(ccType) .. " on " .. targetName
    
    if ccerName then
        message = message .. " (" .. ccerName .. ")"
    end
    
    -- Send to appropriate channel
    local channel = settings.communicationSettings.announceCCChannel
    
    if channel == "Party" and IsInGroup() then
        SendChatMessage(message, "PARTY")
    elseif channel == "Raid" and IsInRaid() then
        SendChatMessage(message, "RAID")
    elseif channel == "Say" then
        SendChatMessage(message, "SAY")
    elseif channel == "Emote" then
        SendChatMessage(message, "EMOTE")
    else
        -- Just print to chat frame
        API.PrintMessage(message)
    end
}

-- Get CC type name
function CCChainAssist:GetCCTypeName(ccType)
    if ccType == CC_TYPE_STUN then
        return "Stun"
    elseif ccType == CC_TYPE_INCAPACITATE then
        return "Incapacitate"
    elseif ccType == CC_TYPE_DISORIENT then
        return "Disorient"
    elseif ccType == CC_TYPE_SILENCE then
        return "Silence"
    elseif ccType == CC_TYPE_FEAR then
        return "Fear"
    elseif ccType == CC_TYPE_ROOT then
        return "Root"
    elseif ccType == CC_TYPE_DISARM then
        return "Disarm"
    elseif ccType == CC_TYPE_SLOWCAST then
        return "Slow Cast"
    else
        return "CC"
    end
end

-- Show target DR status
function CCChainAssist:ShowTargetDRStatus(targetGUID)
    -- Skip if no DR tracking for this target
    if not ccDiminishingReturns[targetGUID] then
        return
    end
    
    -- Debug output
    API.PrintDebug("DR Status for " .. (self:GetUnitNameFromGUID(targetGUID) or "Unknown Target") .. ":")
    
    -- Check DR for each category
    for category, drInfo in pairs(ccDiminishingReturns[targetGUID]) do
        local resetRemaining = drInfo.resetTime - GetTime()
        
        if resetRemaining > 0 then
            local nextFactor = self:GetDRFactor(targetGUID, category)
            local status = nextFactor == 0 and "IMMUNE" or (nextFactor * 100) .. "% duration"
            
            API.PrintDebug("  " .. self:GetDRCategoryName(category) .. ": " .. status .. " (Resets in " .. string.format("%.1f", resetRemaining) .. "s)")
        end
    end
}

-- Get unit name from GUID
function CCChainAssist:GetUnitNameFromGUID(guid)
    local unit = self:GetUnitFromGUID(guid)
    if unit then
        return UnitName(unit)
    end
    
    return nil
end

-- Get DR category name
function CCChainAssist:GetDRCategoryName(category)
    if drCategories[category] then
        return drCategories[category].name
    end
    
    return category
end

-- Suggest CCs for target
function CCChainAssist:SuggestCCsForTarget(unit)
    -- Skip if unit doesn't exist
    if not UnitExists(unit) then
        return
    end
    
    -- Get unit GUID
    local unitGUID = UnitGUID(unit)
    
    -- Debug output
    API.PrintDebug("Suggested CCs for " .. UnitName(unit) .. ":")
    
    -- List available CCs
    local suggestedCCs = {}
    
    for _, ccSpell in ipairs(playerCCs) do
        -- Skip if on cooldown
        if self:IsSpellOnCooldown(ccSpell.spellID) then
            goto continue
        end
        
        -- Skip if target is immune to this DR category
        if self:IsTargetImmuneToCC(unitGUID, ccSpell.drCategory, ccSpell.type) then
            goto continue
        end
        
        -- Skip if target doesn't match allowed target types
        if ccSpell.targetTypes and not self:DoesTargetMatchTypes(unitGUID, ccSpell.targetTypes) then
            goto continue
        end
        
        -- Skip if requires stealth and player is not stealthed
        if ccSpell.stealth and not IsStealthed() then
            goto continue
        end
        
        -- Calculate effective duration
        local duration = ccSpell.duration
        if ccSpell.drCategory then
            duration = duration * self:GetDRFactor(unitGUID, ccSpell.drCategory)
        end
        
        -- Add to suggested CCs
        table.insert(suggestedCCs, {
            spellID = ccSpell.spellID,
            name = ccSpell.name,
            type = ccSpell.type,
            duration = duration,
            priority = ccSpell.priority
        })
        
        ::continue::
    end
    
    -- Sort by priority
    table.sort(suggestedCCs, function(a, b) return a.priority > b.priority end)
    
    -- Output suggestions
    for i, cc in ipairs(suggestedCCs) do
        if i <= 3 then -- Limit to top 3
            API.PrintDebug("  " .. cc.name .. " (" .. cc.type .. ", " .. string.format("%.1f", cc.duration) .. "s)")
        end
    end
end

-- Toggle enabled state
function CCChainAssist:Toggle()
    isEnabled = not isEnabled
    
    if isEnabled then
        ccMonitorFrame:Show()
    else
        ccMonitorFrame:Hide()
    end
    
    return isEnabled
end

-- Is enabled
function CCChainAssist:IsEnabled()
    return isEnabled
end

-- Return the module
return CCChainAssist