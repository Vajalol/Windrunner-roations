------------------------------------------
-- WindrunnerRotations - Group Role Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local GroupRoleManager = {}
WR.GroupRoleManager = GroupRoleManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager

-- Data storage
local raidMembers = {}
local groupComposition = {}
local groupSize = 0
local inGroup = false
local inRaid = false
local tankCount = 0
local healerCount = 0
local meleeCount = 0
local rangedCount = 0
local groupAuras = {}
local roleDetectionMethod = "auto"
local isMainTank = false
local isMainHealer = false
local tankAssignments = {}
local healerAssignments = {}
local groupFormation = "unknown"
local playerRole = "unknown"
local trackedGameEvents = {}
local partyUtilitySpells = {}
local groupBuffs = {}
local lastRaidEvaluation = 0
local RAID_EVAL_FREQUENCY = 1.0 -- How often to re-evaluate raid roles (seconds)

-- Role constants
local ROLE_TANK = "TANK"
local ROLE_HEALER = "HEALER"
local ROLE_DAMAGER = "DAMAGER"

-- Group types
local GROUP_TYPE_SOLO = "solo"
local GROUP_TYPE_PARTY = "party"
local GROUP_TYPE_RAID = "raid"
local GROUP_TYPE_BATTLEGROUND = "battleground"
local GROUP_TYPE_ARENA = "arena"

-- Group formations
local GROUP_FORMATION_STANDARD = "standard"     -- Standard group/raid
local GROUP_FORMATION_MYTHICPLUS = "mythicplus" -- Mythic+ group (1 tank, 1 healer, 3 dps)
local GROUP_FORMATION_RAID = "raid"             -- Raid (2 tanks, 3-5 healers, rest dps)
local GROUP_FORMATION_RBG = "rbg"               -- Rated Battleground specific
local GROUP_FORMATION_2V2 = "2v2"               -- 2v2 Arena
local GROUP_FORMATION_3V3 = "3v3"               -- 3v3 Arena

-- Spec roles mapping
local classSpecRoles = {
    ["DEATHKNIGHT"] = { [1] = ROLE_TANK, [2] = ROLE_DAMAGER, [3] = ROLE_DAMAGER },
    ["DEMONHUNTER"] = { [1] = ROLE_DAMAGER, [2] = ROLE_TANK },
    ["DRUID"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_TANK, [4] = ROLE_HEALER },
    ["HUNTER"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_DAMAGER },
    ["MAGE"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_DAMAGER },
    ["MONK"] = { [1] = ROLE_TANK, [2] = ROLE_HEALER, [3] = ROLE_DAMAGER },
    ["PALADIN"] = { [1] = ROLE_HEALER, [2] = ROLE_TANK, [3] = ROLE_DAMAGER },
    ["PRIEST"] = { [1] = ROLE_HEALER, [2] = ROLE_HEALER, [3] = ROLE_DAMAGER },
    ["ROGUE"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_DAMAGER },
    ["SHAMAN"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_HEALER },
    ["WARLOCK"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_DAMAGER },
    ["WARRIOR"] = { [1] = ROLE_DAMAGER, [2] = ROLE_DAMAGER, [3] = ROLE_TANK },
    ["EVOKER"] = { [1] = ROLE_DAMAGER, [2] = ROLE_HEALER, [3] = ROLE_DAMAGER }
}

-- Melee classes and specs
local meleeClasses = {
    ["WARRIOR"] = true,
    ["PALADIN"] = { [3] = true }, -- Retribution only
    ["ROGUE"] = true,
    ["DEATHKNIGHT"] = true,
    ["MONK"] = { [1] = true, [3] = true }, -- Brewmaster and Windwalker
    ["DEMONHUNTER"] = true,
    ["DRUID"] = { [2] = true, [3] = true }, -- Feral and Guardian
    ["SHAMAN"] = { [2] = true }, -- Enhancement only
    ["HUNTER"] = { [3] = true }  -- Survival only
}

-- Initialize the Group Role Manager
function GroupRoleManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize party utility spells
    self:InitializePartyUtilitySpells()
    
    -- Initialize group buffs
    self:InitializeGroupBuffs()
    
    -- Update current group state
    self:UpdateGroupState()
    
    API.PrintDebug("Group Role Manager initialized")
    return true
end

-- Register settings
function GroupRoleManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("GroupRoleManager", {
        generalSettings = {
            enableRoleDetection = {
                displayName = "Enable Role Detection",
                description = "Auto-detect roles in group and adjust rotation",
                type = "toggle",
                default = true
            },
            roleDetectionMethod = {
                displayName = "Role Detection Method",
                description = "How to detect roles in group",
                type = "dropdown",
                options = {"Auto", "LFG Role", "Spec-Based", "Aura-Based", "Talent-Based"},
                default = "Auto"
            },
            treatSoloAsMythicPlus = {
                displayName = "Treat Solo as Mythic+",
                description = "Use Mythic+ rotation even when playing solo",
                type = "toggle",
                default = false
            },
            detectInstanceType = {
                displayName = "Detect Instance Type",
                description = "Auto-detect dungeon, raid, arena, etc.",
                type = "toggle",
                default = true
            }
        },
        groupSettings = {
            adaptToGroupComposition = {
                displayName = "Adapt to Group Composition",
                description = "Adjust rotation based on group composition",
                type = "toggle",
                default = true
            },
            improveGroupSynergy = {
                displayName = "Improve Group Synergy",
                description = "Adjust rotation to benefit from group buffs and synergies",
                type = "toggle",
                default = true
            },
            supportTeamStrategy = {
                displayName = "Support Team Strategy",
                description = "Adjust rotation to support team's play style",
                type = "toggle",
                default = true
            },
            reactToGroupNeeds = {
                displayName = "React to Group Needs",
                description = "Adjust rotation based on group's needs (health, resources, etc.)",
                type = "toggle",
                default = true
            }
        },
        tankSettings = {
            enableTankMode = {
                displayName = "Enable Tank Mode",
                description = "Enable specialized rotations for tanks",
                type = "toggle",
                default = true
            },
            assumeTankResponsibility = {
                displayName = "Assume Tank Responsibility",
                description = "Auto-taunt and use tank abilities even if not assigned as tank",
                type = "toggle",
                default = false
            },
            tankThreatPriority = {
                displayName = "Tank Threat Priority",
                description = "Priority of generating threat vs. damage",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 7
            },
            tankMitigationPriority = {
                displayName = "Tank Mitigation Priority",
                description = "Priority of damage mitigation vs. self-healing",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            }
        },
        healerSettings = {
            enableHealerMode = {
                displayName = "Enable Healer Mode",
                description = "Enable specialized rotations for healers",
                type = "toggle",
                default = true
            },
            assumeHealerResponsibility = {
                displayName = "Assume Healer Responsibility",
                description = "Auto-heal group members even if not assigned as healer",
                type = "toggle",
                default = false
            },
            healerEfficiencyPriority = {
                displayName = "Healer Efficiency Priority",
                description = "Priority of mana efficiency vs. raw healing",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            },
            prioritizeGroupHealing = {
                displayName = "Prioritize Group Healing",
                description = "Focus on group healing vs. single target healing",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 5
            }
        },
        damagerSettings = {
            adaptToBurstWindows = {
                displayName = "Adapt to Burst Windows",
                description = "Adjust rotation to align with group burst windows",
                type = "toggle",
                default = true
            },
            supportGroupUtility = {
                displayName = "Support Group Utility",
                description = "Provide utility support even at the cost of some DPS",
                type = "toggle",
                default = true
            },
            adjustAoEThreshold = {
                displayName = "Adjust AoE Threshold",
                description = "Adjust AoE target threshold based on group composition",
                type = "toggle",
                default = true
            },
            prioritizeProgressionMechanics = {
                displayName = "Prioritize Progression Mechanics",
                description = "Focus on mechanics in progression content even at DPS loss",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Register for events
function GroupRoleManager:RegisterEvents()
    -- Register for group events
    API.RegisterEvent("GROUP_ROSTER_UPDATE", function()
        self:OnGroupRosterUpdate()
    end)
    
    API.RegisterEvent("PLAYER_ROLES_ASSIGNED", function()
        self:OnRolesAssigned()
    end)
    
    -- Register for instance events
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:OnPlayerEnteringWorld()
    end)
    
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
    
    -- Register for raid target marker events
    API.RegisterEvent("RAID_TARGET_UPDATE", function()
        self:OnRaidTargetUpdate()
    end)
    
    -- Register for player specialization changed
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnPlayerSpecializationChanged()
        else
            self:OnUnitSpecializationChanged(unit)
        end
    end)
    
    -- Register for talent changes
    API.RegisterEvent("PLAYER_TALENT_UPDATE", function()
        self:OnPlayerTalentUpdate()
    end)
    
    -- Register for aura change events
    API.RegisterEvent("UNIT_AURA", function(unit)
        self:OnUnitAuraChanged(unit)
    end)
    
    -- Register for combat events
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnCombatStart()
    end)
    
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnCombatEnd()
    end)
    
    -- Register a ticker to update roles
    C_Timer.NewTicker(RAID_EVAL_FREQUENCY, function()
        self:UpdateRaidRoles()
    end)
}

-- Initialize party utility spells
function GroupRoleManager:InitializePartyUtilitySpells()
    partyUtilitySpells = {
        -- Bloodlust-type effects
        [2825] = {name = "Bloodlust", class = "SHAMAN", similar = {"heroism", "timewarp", "primalrage", "ancienthysteria", "netherwinds", "drums"}},
        [32182] = {name = "Heroism", class = "SHAMAN", similar = {"bloodlust", "timewarp", "primalrage", "ancienthysteria", "netherwinds", "drums"}},
        [80353] = {name = "Time Warp", class = "MAGE", similar = {"bloodlust", "heroism", "primalrage", "ancienthysteria", "netherwinds", "drums"}},
        [264667] = {name = "Primal Rage", class = "HUNTER", similar = {"bloodlust", "heroism", "timewarp", "ancienthysteria", "netherwinds", "drums"}},
        [90355] = {name = "Ancient Hysteria", petType = "Corehound", similar = {"bloodlust", "heroism", "timewarp", "primalrage", "netherwinds", "drums"}},
        [160452] = {name = "Netherwinds", petType = "Nether Ray", similar = {"bloodlust", "heroism", "timewarp", "primalrage", "ancienthysteria", "drums"}},
        
        -- Battle rez effects
        [20484] = {name = "Rebirth", class = "DRUID", similar = {"battlerez", "resurrection"}},
        [20707] = {name = "Soulstone", class = "WARLOCK", similar = {"battlerez", "resurrection"}},
        [95750] = {name = "Soulstone Resurrection", class = "WARLOCK", similar = {"battlerez", "resurrection"}},
        [21169] = {name = "Reincarnation", class = "SHAMAN", similar = {"battlerez", "resurrection"}},
        [159931] = {name = "Gift of Chi-Ji", class = "MONK", similar = {"battlerez", "resurrection"}},
        [61999] = {name = "Raise Ally", class = "DEATHKNIGHT", similar = {"battlerez", "resurrection"}},
        [95750] = {name = "Soulstone Resurrection", class = "WARLOCK", similar = {"battlerez", "resurrection"}},
        
        -- Major party cooldowns
        [98008] = {name = "Spirit Link Totem", class = "SHAMAN", role = ROLE_HEALER, type = "raidcd"},
        [31821] = {name = "Aura Mastery", class = "PALADIN", role = ROLE_HEALER, type = "raidcd"},
        [64843] = {name = "Divine Hymn", class = "PRIEST", role = ROLE_HEALER, type = "raidcd"},
        [740] = {name = "Tranquility", class = "DRUID", role = ROLE_HEALER, type = "raidcd"},
        [115310] = {name = "Revival", class = "MONK", role = ROLE_HEALER, type = "raidcd"},
        [97462] = {name = "Rallying Cry", class = "WARRIOR", role = ROLE_TANK, type = "raidcd"},
        [51052] = {name = "Anti-Magic Zone", class = "DEATHKNIGHT", role = ROLE_TANK, type = "raidcd"},
        [196718] = {name = "Darkness", class = "DEMONHUNTER", role = ROLE_DAMAGER, type = "raidcd"},
        [363534] = {name = "Rewind", class = "EVOKER", role = ROLE_HEALER, type = "raidcd"},
        
        -- Utility spells
        [6940] = {name = "Blessing of Sacrifice", class = "PALADIN", role = ROLE_HEALER, type = "utility"},
        [192077] = {name = "Wind Rush Totem", class = "SHAMAN", type = "utility"},
        [1022] = {name = "Blessing of Protection", class = "PALADIN", type = "utility"},
        [10060] = {name = "Power Infusion", class = "PRIEST", type = "utility"},
        [33206] = {name = "Pain Suppression", class = "PRIEST", role = ROLE_HEALER, type = "utility"},
        [2094] = {name = "Blind", class = "ROGUE", type = "utility"},
        [355913] = {name = "Emerald Communion", class = "EVOKER", type = "utility"},
        [102342] = {name = "Ironbark", class = "DRUID", role = ROLE_HEALER, type = "utility"},
        [116849] = {name = "Life Cocoon", class = "MONK", role = ROLE_HEALER, type = "utility"},
        [633] = {name = "Lay on Hands", class = "PALADIN", type = "utility"}
    }
}

-- Initialize group buffs
function GroupRoleManager:InitializeGroupBuffs()
    groupBuffs = {
        -- Class buffs
        [21562] = {name = "Power Word: Fortitude", class = "PRIEST", type = "stamina"},
        [1459] = {name = "Arcane Intellect", class = "MAGE", type = "intellect"},
        [6673] = {name = "Battle Shout", class = "WARRIOR", type = "attack_power"},
        [116781] = {name = "Legacy of the White Tiger", class = "MONK", type = "crit"},
        [1126] = {name = "Mark of the Wild", class = "DRUID", type = "versatility"},
        [203538] = {name = "Greater Blessing of Kings", class = "PALADIN", type = "mastery"},
        [203539] = {name = "Greater Blessing of Wisdom", class = "PALADIN", type = "mp5"},
        [264761] = {name = "War-Scroll of Battle Shout", type = "attack_power"},
        [264760] = {name = "War-Scroll of Intellect", type = "intellect"}
    }
}

-- Update group state
function GroupRoleManager:UpdateGroupState()
    -- Check if in group
    inGroup = IsInGroup()
    inRaid = IsInRaid()
    
    -- Get group size
    if inRaid then
        groupSize = GetNumGroupMembers()
    elseif inGroup then
        groupSize = GetNumGroupMembers()
    else
        groupSize = 1
    end
    
    -- Determine group type
    local groupType = self:GetGroupType()
    
    -- Update player role
    self:UpdatePlayerRole()
    
    -- Build group composition
    self:BuildGroupComposition()
    
    -- Determine group formation
    groupFormation = self:DetermineGroupFormation()
    
    -- Detect if player is main tank/healer
    self:DetectMainRoles()
    
    -- Update group auras
    self:UpdateGroupAuras()
    
    API.PrintDebug("Group state updated: " .. (inGroup and (inRaid and "Raid" or "Party") or "Solo") .. ", Size: " .. groupSize .. ", Type: " .. groupType .. ", Formation: " .. groupFormation)
}

-- On group roster update
function GroupRoleManager:OnGroupRosterUpdate()
    self:UpdateGroupState()
}

-- On roles assigned
function GroupRoleManager:OnRolesAssigned()
    self:UpdatePlayerRole()
    self:BuildGroupComposition()
    self:DetectMainRoles()
}

-- On player entering world
function GroupRoleManager:OnPlayerEnteringWorld()
    self:UpdateGroupState()
}

-- On zone changed
function GroupRoleManager:OnZoneChanged()
    self:UpdateGroupState()
}

-- On raid target update
function GroupRoleManager:OnRaidTargetUpdate()
    -- Update tank assignments based on raid markers
    self:UpdateTankAssignments()
}

-- On player specialization changed
function GroupRoleManager:OnPlayerSpecializationChanged()
    self:UpdatePlayerRole()
}

-- On unit specialization changed
function GroupRoleManager:OnUnitSpecializationChanged(unit)
    -- Update group composition when a group member changes spec
    self:BuildGroupComposition()
}

-- On player talent update
function GroupRoleManager:OnPlayerTalentUpdate()
    self:UpdatePlayerRole()
}

-- On unit aura changed
function GroupRoleManager:OnUnitAuraChanged(unit)
    -- Update group auras if needed
    if UnitIsPlayer(unit) and (UnitInParty(unit) or UnitInRaid(unit) or unit == "player") then
        self:UpdateUnitAuras(unit)
    end
}

-- On combat start
function GroupRoleManager:OnCombatStart()
    -- Update raid roles when entering combat
    self:UpdateRaidRoles()
    
    -- Track combat event
    self:TrackGameEvent("combat_start")
}

-- On combat end
function GroupRoleManager:OnCombatEnd()
    -- Track combat event
    self:TrackGameEvent("combat_end")
}

-- Update raid roles
function GroupRoleManager:UpdateRaidRoles()
    local now = GetTime()
    
    -- Only update if it's been long enough since last update
    if now - lastRaidEvaluation < RAID_EVAL_FREQUENCY then
        return
    end
    
    lastRaidEvaluation = now
    
    -- Reset counters
    tankCount = 0
    healerCount = 0
    meleeCount = 0
    rangedCount = 0
    
    -- Check player
    local playerRole = self:GetUnitRole("player")
    if playerRole == ROLE_TANK then
        tankCount = tankCount + 1
    elseif playerRole == ROLE_HEALER then
        healerCount = healerCount + 1
    elseif self:IsUnitMelee("player") then
        meleeCount = meleeCount + 1
    else
        rangedCount = rangedCount + 1
    end
    
    -- Check party/raid members
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                local role = self:GetUnitRole(unit)
                
                if role == ROLE_TANK then
                    tankCount = tankCount + 1
                elseif role == ROLE_HEALER then
                    healerCount = healerCount + 1
                elseif self:IsUnitMelee(unit) then
                    meleeCount = meleeCount + 1
                else
                    rangedCount = rangedCount + 1
                end
            end
        end
    end
    
    -- Update group composition
    groupComposition.tankCount = tankCount
    groupComposition.healerCount = healerCount
    groupComposition.meleeCount = meleeCount
    groupComposition.rangedCount = rangedCount
    groupComposition.totalCount = tankCount + healerCount + meleeCount + rangedCount
    
    -- Debug output
    API.PrintDebug("Group composition: " .. 
                   tankCount .. " tanks, " .. 
                   healerCount .. " healers, " .. 
                   meleeCount .. " melee, " .. 
                   rangedCount .. " ranged")
}

-- Build group composition
function GroupRoleManager:BuildGroupComposition()
    -- Create a table to store group composition
    groupComposition = {
        tankCount = 0,
        healerCount = 0,
        meleeCount = 0,
        rangedCount = 0,
        totalCount = 0,
        members = {},
        buffs = {},
        debuffs = {}
    }
    
    -- Add player to group composition
    local playerSpec = API.GetActiveSpecID()
    local playerClass = select(2, UnitClass("player"))
    local playerRole = self:GetUnitRole("player")
    
    groupComposition.members["player"] = {
        name = UnitName("player"),
        class = playerClass,
        spec = playerSpec,
        role = playerRole,
        isMelee = self:IsUnitMelee("player"),
        isTank = playerRole == ROLE_TANK,
        isHealer = playerRole == ROLE_HEALER,
        isDamager = playerRole == ROLE_DAMAGER,
        hasBloodlust = self:HasBloodlust(playerClass),
        hasBattleRez = self:HasBattleRez(playerClass),
        hasRaidCD = self:HasRaidCD(playerClass, playerRole)
    }
    
    -- Update counters based on player role
    if playerRole == ROLE_TANK then
        groupComposition.tankCount = groupComposition.tankCount + 1
    elseif playerRole == ROLE_HEALER then
        groupComposition.healerCount = groupComposition.healerCount + 1
    elseif self:IsUnitMelee("player") then
        groupComposition.meleeCount = groupComposition.meleeCount + 1
    else
        groupComposition.rangedCount = groupComposition.rangedCount + 1
    end
    
    -- Add party/raid members to group composition
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                local name = UnitName(unit)
                local class = select(2, UnitClass(unit))
                local role = self:GetUnitRole(unit)
                local isMelee = self:IsUnitMelee(unit)
                
                groupComposition.members[unit] = {
                    name = name,
                    class = class,
                    spec = nil, -- We don't know this yet
                    role = role,
                    isMelee = isMelee,
                    isTank = role == ROLE_TANK,
                    isHealer = role == ROLE_HEALER,
                    isDamager = role == ROLE_DAMAGER,
                    hasBloodlust = self:HasBloodlust(class),
                    hasBattleRez = self:HasBattleRez(class),
                    hasRaidCD = self:HasRaidCD(class, role)
                }
                
                -- Update counters based on role
                if role == ROLE_TANK then
                    groupComposition.tankCount = groupComposition.tankCount + 1
                elseif role == ROLE_HEALER then
                    groupComposition.healerCount = groupComposition.healerCount + 1
                elseif isMelee then
                    groupComposition.meleeCount = groupComposition.meleeCount + 1
                else
                    groupComposition.rangedCount = groupComposition.rangedCount + 1
                end
            end
        end
    end
    
    -- Update total count
    groupComposition.totalCount = groupComposition.tankCount + groupComposition.healerCount + 
                                 groupComposition.meleeCount + groupComposition.rangedCount
    
    -- Check for bloodlust and battle rez availability
    groupComposition.hasBloodlust = false
    groupComposition.hasBattleRez = false
    
    for _, member in pairs(groupComposition.members) do
        if member.hasBloodlust then
            groupComposition.hasBloodlust = true
        end
        
        if member.hasBattleRez then
            groupComposition.hasBattleRez = true
        end
    end
    
    -- Update available buffs and debuffs
    self:UpdateGroupBuffsDebuffs()
}

-- Check if class has bloodlust
function GroupRoleManager:HasBloodlust(class)
    return class == "SHAMAN" or class == "MAGE" or class == "HUNTER"
}

-- Check if class has battle rez
function GroupRoleManager:HasBattleRez(class)
    return class == "DRUID" or class == "WARLOCK" or class == "DEATHKNIGHT"
}

-- Check if class/role has raid CD
function GroupRoleManager:HasRaidCD(class, role)
    for _, spell in pairs(partyUtilitySpells) do
        if spell.class == class and (not spell.role or spell.role == role) and spell.type == "raidcd" then
            return true
        end
    end
    
    return false
}

-- Get group type
function GroupRoleManager:GetGroupType()
    -- Check for arena
    if C_PvP.IsArena() then
        return GROUP_TYPE_ARENA
    end
    
    -- Check for battleground
    if UnitInBattleground("player") then
        return GROUP_TYPE_BATTLEGROUND
    end
    
    -- Check for raid
    if inRaid then
        return GROUP_TYPE_RAID
    end
    
    -- Check for party
    if inGroup then
        return GROUP_TYPE_PARTY
    end
    
    -- Solo play
    return GROUP_TYPE_SOLO
end

-- Update player role
function GroupRoleManager:UpdatePlayerRole()
    local settings = ConfigRegistry:GetSettings("GroupRoleManager")
    
    -- Skip if role detection is disabled
    if not settings.generalSettings.enableRoleDetection then
        return
    end
    
    -- Determine role detection method
    roleDetectionMethod = string.lower(settings.generalSettings.roleDetectionMethod)
    
    -- Get player role based on method
    if roleDetectionMethod == "auto" then
        -- Try all methods in order of reliability
        playerRole = self:GetRoleFromLFG("player") or 
                    self:GetRoleFromSpec("player") or 
                    self:GetRoleFromAuras("player") or 
                    self:GetRoleFromTalents("player") or 
                    "unknown"
    elseif roleDetectionMethod == "lfg role" then
        playerRole = self:GetRoleFromLFG("player") or "unknown"
    elseif roleDetectionMethod == "spec-based" then
        playerRole = self:GetRoleFromSpec("player") or "unknown"
    elseif roleDetectionMethod == "aura-based" then
        playerRole = self:GetRoleFromAuras("player") or "unknown"
    elseif roleDetectionMethod == "talent-based" then
        playerRole = self:GetRoleFromTalents("player") or "unknown"
    else
        playerRole = "unknown"
    end
    
    -- Override based on settings
    if settings.tankSettings.assumeTankResponsibility and settings.tankSettings.enableTankMode then
        playerRole = ROLE_TANK
    elseif settings.healerSettings.assumeHealerResponsibility and settings.healerSettings.enableHealerMode then
        playerRole = ROLE_HEALER
    end
    
    API.PrintDebug("Player role detected: " .. playerRole)
}

-- Determine group formation
function GroupRoleManager:DetermineGroupFormation()
    local settings = ConfigRegistry:GetSettings("GroupRoleManager")
    local groupType = self:GetGroupType()
    
    -- Solo play
    if groupType == GROUP_TYPE_SOLO then
        if settings.generalSettings.treatSoloAsMythicPlus then
            return GROUP_FORMATION_MYTHICPLUS
        else
            return GROUP_FORMATION_STANDARD
        end
    end
    
    -- Arena
    if groupType == GROUP_TYPE_ARENA then
        local arenaSize = C_PvP.GetActiveArenaSkirmishSize()
        if arenaSize == 2 then
            return GROUP_FORMATION_2V2
        elseif arenaSize == 3 then
            return GROUP_FORMATION_3V3
        else
            return GROUP_FORMATION_STANDARD
        end
    end
    
    -- Battleground
    if groupType == GROUP_TYPE_BATTLEGROUND then
        if C_PvP.IsRatedBattleground() then
            return GROUP_FORMATION_RBG
        else
            return GROUP_FORMATION_STANDARD
        end
    end
    
    -- Raid or party
    if inRaid then
        return GROUP_FORMATION_RAID
    else
        -- Check for Mythic+ dungeon
        local _, instanceType, difficultyID = GetInstanceInfo()
        if instanceType == "party" and (difficultyID == 8 or difficultyID == 23) then
            return GROUP_FORMATION_MYTHICPLUS
        else
            return GROUP_FORMATION_STANDARD
        end
    end
end

-- Detect if player is main tank/healer
function GroupRoleManager:DetectMainRoles()
    isMainTank = false
    isMainHealer = false
    
    -- Solo play - always main role
    if not inGroup then
        isMainTank = playerRole == ROLE_TANK
        isMainHealer = playerRole == ROLE_HEALER
        return
    end
    
    -- If player is not tank/healer, they can't be main tank/healer
    if playerRole ~= ROLE_TANK and playerRole ~= ROLE_HEALER then
        return
    end
    
    -- Get assigned tanks and healers
    local assignedTanks = {}
    local assignedHealers = {}
    
    -- Add player if they're a tank/healer
    if playerRole == ROLE_TANK then
        assignedTanks["player"] = true
    elseif playerRole == ROLE_HEALER then
        assignedHealers["player"] = true
    end
    
    -- Check party/raid for assigned roles
    local prefix = inRaid and "raid" or "party"
    local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
    
    for i = 1, count do
        local unit = prefix .. i
        
        if UnitExists(unit) then
            local role = self:GetUnitRole(unit)
            
            if role == ROLE_TANK then
                assignedTanks[unit] = true
            elseif role == ROLE_HEALER then
                assignedHealers[unit] = true
            end
        end
    end
    
    -- Count tanks and healers
    local tankCount = 0
    local healerCount = 0
    
    for _ in pairs(assignedTanks) do
        tankCount = tankCount + 1
    end
    
    for _ in pairs(assignedHealers) do
        healerCount = healerCount + 1
    end
    
    -- Determine if player is main tank/healer
    if playerRole == ROLE_TANK then
        -- In M+, there's only one tank
        if tankCount == 1 or groupFormation == GROUP_FORMATION_MYTHICPLUS then
            isMainTank = true
        else
            -- In raids, check for tank assignments
            isMainTank = tankAssignments["player"] ~= nil
        end
    elseif playerRole == ROLE_HEALER then
        -- In small groups, there's often only one healer
        if healerCount == 1 or groupFormation == GROUP_FORMATION_MYTHICPLUS then
            isMainHealer = true
        else
            -- In raids with multiple healers, check for healer assignments
            isMainHealer = healerAssignments["player"] ~= nil
        end
    end
}

-- Update tank assignments
function GroupRoleManager:UpdateTankAssignments()
    -- Reset tank assignments
    tankAssignments = {}
    
    -- Solo play - no assignments needed
    if not inGroup then
        return
    end
    
    -- In raid groups, tanks are often assigned specific targets
    if inRaid then
        -- Check for raid target markers (tanks often mark their targets)
        for i = 1, 8 do
            local unitWithMark = self:GetUnitWithRaidTargetMark(i)
            
            if unitWithMark then
                -- Find who has this unit targeted
                local tankUnit = self:FindUnitTargeting(unitWithMark)
                
                if tankUnit and self:GetUnitRole(tankUnit) == ROLE_TANK then
                    tankAssignments[tankUnit] = unitWithMark
                end
            end
        end
    else
        -- In 5-man groups, the only tank is assigned to everything
        local tankUnit = self:FindGroupRoleMember(ROLE_TANK)
        
        if tankUnit then
            tankAssignments[tankUnit] = "all"
        end
    end
}

-- Get unit with raid target mark
function GroupRoleManager:GetUnitWithRaidTargetMark(markID)
    -- Check if target has this mark
    if UnitExists("target") and GetRaidTargetIndex("target") == markID then
        return "target"
    end
    
    -- Check if focus has this mark
    if UnitExists("focus") and GetRaidTargetIndex("focus") == markID then
        return "focus"
    end
    
    -- Check nameplates
    for i = 1, 40 do
        local unit = "nameplate" .. i
        
        if UnitExists(unit) and GetRaidTargetIndex(unit) == markID then
            return unit
        end
    end
    
    return nil
end

-- Find unit targeting a specific unit
function GroupRoleManager:FindUnitTargeting(targetUnit)
    -- Check if player is targeting this unit
    if UnitIsUnit("target", targetUnit) then
        return "player"
    end
    
    -- Check if party/raid members are targeting this unit
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) and UnitExists(unit .. "target") and UnitIsUnit(unit .. "target", targetUnit) then
                return unit
            end
        end
    end
    
    return nil
}

-- Find group member with specific role
function GroupRoleManager:FindGroupRoleMember(role)
    -- Check if player has this role
    if playerRole == role then
        return "player"
    end
    
    -- Check if party/raid members have this role
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) and self:GetUnitRole(unit) == role then
                return unit
            end
        end
    end
    
    return nil
}

-- Update group auras
function GroupRoleManager:UpdateGroupAuras()
    -- Reset group auras
    groupAuras = {
        bloodlust = false,
        powerWord = false,
        arcaneIntellect = false,
        battleShout = false,
        markOfTheWild = false,
        blessingOfKings = false,
        blessingOfWisdom = false
    }
    
    -- Check player auras
    self:UpdateUnitAuras("player")
    
    -- Check party/raid members
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                self:UpdateUnitAuras(unit)
            end
        end
    end
}

-- Update unit auras
function GroupRoleManager:UpdateUnitAuras(unit)
    -- Check for bloodlust-type buffs
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, i)
        
        if not name then
            break
        end
        
        -- Check for bloodlust and similar
        if spellID == 2825 or spellID == 32182 or spellID == 80353 or spellID == 264667 or 
           spellID == 90355 or spellID == 160452 then
            groupAuras.bloodlust = true
        end
        
        -- Check for class buffs
        if spellID == 21562 then -- Power Word: Fortitude
            groupAuras.powerWord = true
        elseif spellID == 1459 then -- Arcane Intellect
            groupAuras.arcaneIntellect = true
        elseif spellID == 6673 then -- Battle Shout
            groupAuras.battleShout = true
        elseif spellID == 1126 then -- Mark of the Wild
            groupAuras.markOfTheWild = true
        elseif spellID == 203538 then -- Greater Blessing of Kings
            groupAuras.blessingOfKings = true
        elseif spellID == 203539 then -- Greater Blessing of Wisdom
            groupAuras.blessingOfWisdom = true
        end
    end
}

-- Update group buffs and debuffs
function GroupRoleManager:UpdateGroupBuffsDebuffs()
    -- Clear existing buffs and debuffs
    groupComposition.buffs = {}
    groupComposition.debuffs = {}
    
    -- Check player buffs
    self:AddUnitBuffsToGroup("player")
    
    -- Check party/raid members
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                self:AddUnitBuffsToGroup(unit)
            end
        end
    end
}

-- Add unit buffs to group
function GroupRoleManager:AddUnitBuffsToGroup(unit)
    -- Check unit buffs
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, i)
        
        if not name then
            break
        end
        
        -- Add to group buffs if it's a tracked buff
        if groupBuffs[spellID] then
            local buffType = groupBuffs[spellID].type
            
            if not groupComposition.buffs[buffType] then
                groupComposition.buffs[buffType] = {
                    name = name,
                    spellID = spellID,
                    provider = unit
                }
            end
        end
    end
}

-- Get unit role from LFG
function GroupRoleManager:GetRoleFromLFG(unit)
    -- This only works for party members
    if unit == "player" or UnitInParty(unit) then
        local isTank, isHealer, isDamager = UnitGroupRolesAssigned(unit)
        
        if isTank then
            return ROLE_TANK
        elseif isHealer then
            return ROLE_HEALER
        elseif isDamager then
            return ROLE_DAMAGER
        end
    end
    
    return nil
}

-- Get unit role from spec
function GroupRoleManager:GetRoleFromSpec(unit)
    -- Get class and spec
    local _, class = UnitClass(unit)
    local spec = nil
    
    -- Get spec differently for player vs. others
    if unit == "player" then
        spec = API.GetActiveSpecID()
    else
        -- For other players, this would require using other methods
        -- GetInspectSpecialization isn't available in all contexts
        return nil
    end
    
    -- Map class/spec to role
    if class and spec and classSpecRoles[class] and classSpecRoles[class][spec] then
        return classSpecRoles[class][spec]
    end
    
    return nil
}

-- Get unit role from auras
function GroupRoleManager:GetRoleFromAuras(unit)
    -- Check for tank auras
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, i)
        
        if not name then
            break
        end
        
        -- Check for tank stances/auras
        if spellID == 115069 or -- Monk: Stance of the Sturdy Ox
           spellID == 52437 or  -- Hunter: Defensive Stance (Bear Form)
           spellID == 48263 or  -- DK: Blood Presence
           spellID == 25780 then -- Paladin: Righteous Fury
            return ROLE_TANK
        end
        
        -- Check for healing specs via auras
        if spellID == 137032 or -- Priest: Chakra: Sanctuary
           spellID == 197030 then -- Paladin: Divinity
            return ROLE_HEALER
        end
    end
    
    return nil
}

-- Get unit role from talents
function GroupRoleManager:GetRoleFromTalents(unit)
    -- This only works for the player
    if unit ~= "player" then
        return nil
    end
    
    -- Get class
    local _, class = UnitClass(unit)
    
    -- Get active spec index
    local specIndex = GetSpecialization()
    
    if not class or not specIndex then
        return nil
    end
    
    -- Map class/spec to role
    if classSpecRoles[class] and classSpecRoles[class][specIndex] then
        return classSpecRoles[class][specIndex]
    end
    
    return nil
}

-- Is unit melee
function GroupRoleManager:IsUnitMelee(unit)
    -- Get class and spec
    local _, class = UnitClass(unit)
    local spec = nil
    
    -- Get spec differently for player vs. others
    if unit == "player" then
        spec = API.GetActiveSpecID()
    else
        -- For other players, this would require using other methods
        -- Most reliable in a real addon would be checking weapon types or attack range
        spec = 1 -- Placeholder
    end
    
    -- Check if class is always melee
    if meleeClasses[class] and type(meleeClasses[class]) == "boolean" then
        return true
    end
    
    -- Check if spec is melee for this class
    if meleeClasses[class] and type(meleeClasses[class]) == "table" and spec and meleeClasses[class][spec] then
        return true
    end
    
    return false
}

-- Get unit role
function GroupRoleManager:GetUnitRole(unit)
    -- Check if unit exists
    if not UnitExists(unit) then
        return ROLE_DAMAGER
    end
    
    -- For player, use the detected role
    if unit == "player" then
        if playerRole ~= "unknown" then
            return playerRole
        end
    end
    
    -- Try to get role from LFG
    local role = self:GetRoleFromLFG(unit)
    if role then
        return role
    end
    
    -- Fall back to spec-based role (only works for inspected players)
    role = self:GetRoleFromSpec(unit)
    if role then
        return role
    end
    
    -- Default to damager
    return ROLE_DAMAGER
}

-- Track game event
function GroupRoleManager:TrackGameEvent(eventType, eventData)
    -- Add event to tracked events
    table.insert(trackedGameEvents, {
        type = eventType,
        timestamp = GetTime(),
        data = eventData or {}
    })
    
    -- Keep only the last 100 events
    if #trackedGameEvents > 100 then
        table.remove(trackedGameEvents, 1)
    end
}

-- Check if we need specific class buffs
function GroupRoleManager:NeedClassBuffs()
    local missingBuffs = {}
    
    -- Check for missing important buffs
    if not groupAuras.powerWord then
        table.insert(missingBuffs, "Power Word: Fortitude")
    end
    
    if not groupAuras.arcaneIntellect and self:GroupHasIntellectUsers() then
        table.insert(missingBuffs, "Arcane Intellect")
    end
    
    if not groupAuras.battleShout and self:GroupHasAttackPowerUsers() then
        table.insert(missingBuffs, "Battle Shout")
    end
    
    return missingBuffs
}

-- Check if group has intellect users
function GroupRoleManager:GroupHasIntellectUsers()
    -- Check player
    local _, playerClass = UnitClass("player")
    if playerClass == "MAGE" or playerClass == "WARLOCK" or playerClass == "PRIEST" or 
       playerClass == "DRUID" or playerClass == "SHAMAN" then
        return true
    end
    
    -- Check party/raid members
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                local _, class = UnitClass(unit)
                if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or 
                   class == "DRUID" or class == "SHAMAN" then
                    return true
                end
            end
        end
    end
    
    return false
}

-- Check if group has attack power users
function GroupRoleManager:GroupHasAttackPowerUsers()
    -- Check player
    local _, playerClass = UnitClass("player")
    if playerClass == "WARRIOR" or playerClass == "PALADIN" or playerClass == "HUNTER" or 
       playerClass == "ROGUE" or playerClass == "DEATHKNIGHT" or playerClass == "MONK" or
       playerClass == "DEMONHUNTER" or playerClass == "DRUID" then
        return true
    end
    
    -- Check party/raid members
    if inGroup then
        local prefix = inRaid and "raid" or "party"
        local count = inRaid and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) then
                local _, class = UnitClass(unit)
                if class == "WARRIOR" or class == "PALADIN" or class == "HUNTER" or 
                   class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or
                   class == "DEMONHUNTER" or class == "DRUID" then
                    return true
                end
            end
        end
    end
    
    return false
}

-- Is bloodlust active
function GroupRoleManager:IsBloodlustActive()
    return groupAuras.bloodlust
}

-- Should self buff
function GroupRoleManager:ShouldSelfBuff()
    local _, playerClass = UnitClass("player")
    
    -- Check for class-specific buffs
    if playerClass == "PRIEST" and not groupAuras.powerWord then
        return "Power Word: Fortitude"
    elseif playerClass == "MAGE" and not groupAuras.arcaneIntellect and self:GroupHasIntellectUsers() then
        return "Arcane Intellect"
    elseif playerClass == "WARRIOR" and not groupAuras.battleShout and self:GroupHasAttackPowerUsers() then
        return "Battle Shout"
    elseif playerClass == "DRUID" and not groupAuras.markOfTheWild then
        return "Mark of the Wild"
    elseif playerClass == "PALADIN" and not groupAuras.blessingOfKings then
        return "Greater Blessing of Kings"
    end
    
    return nil
}

-- Get group formation
function GroupRoleManager:GetGroupFormation()
    return groupFormation
end

-- Is main tank
function GroupRoleManager:IsMainTank()
    return isMainTank
}

-- Is main healer
function GroupRoleManager:IsMainHealer()
    return isMainHealer
}

-- Get player role
function GroupRoleManager:GetPlayerRole()
    return playerRole
}

-- Get group composition
function GroupRoleManager:GetGroupComposition()
    return groupComposition
end

-- Return true if we're in a group
function GroupRoleManager:IsInGroup()
    return inGroup
end

-- Return true if we're in a raid
function GroupRoleManager:IsInRaid()
    return inRaid
}

-- Get tank count
function GroupRoleManager:GetTankCount()
    return tankCount
}

-- Get healer count
function GroupRoleManager:GetHealerCount()
    return healerCount
}

-- Get melee count
function GroupRoleManager:GetMeleeCount()
    return meleeCount
}

-- Get ranged count
function GroupRoleManager:GetRangedCount()
    return rangedCount
}

-- Should optimize AOE
function GroupRoleManager:ShouldOptimizeAOE()
    -- In M+, always optimize for AOE
    if groupFormation == GROUP_FORMATION_MYTHICPLUS then
        return true
    end
    
    -- In raids, optimize based on number of ranged DPS
    if groupFormation == GROUP_FORMATION_RAID and rangedCount > meleeCount then
        return true
    end
    
    return false
}

-- Should optimize for movement
function GroupRoleManager:ShouldOptimizeForMovement()
    -- In M+, always optimize for movement
    if groupFormation == GROUP_FORMATION_MYTHICPLUS then
        return true
    end
    
    -- In raids, typically yes
    if groupFormation == GROUP_FORMATION_RAID then
        return true
    end
    
    return false
}

-- Should use defensive rotation
function GroupRoleManager:ShouldUseDefensiveRotation()
    local settings = ConfigRegistry:GetSettings("GroupRoleManager")
    
    -- If we're a tank, yes
    if playerRole == ROLE_TANK then
        return true
    end
    
    -- In challenging content, probably
    if groupFormation == GROUP_FORMATION_MYTHICPLUS then
        return true
    end
    
    -- If healer count is low relative to group size
    if inGroup and healerCount < groupSize / 5 then
        return true
    end
    
    return false
}

-- Should use mana conservative rotation
function GroupRoleManager:ShouldUseConservativeManaRotation()
    local settings = ConfigRegistry:GetSettings("GroupRoleManager")
    
    -- If we're a healer, maybe
    if playerRole == ROLE_HEALER then
        -- If it's a longer fight, yes
        if groupFormation == GROUP_FORMATION_RAID then
            return true
        end
    end
    
    -- Classes with mana should be conservative in longer fights
    local _, playerClass = UnitClass("player")
    if playerClass == "MAGE" or playerClass == "WARLOCK" or playerClass == "PRIEST" or
       playerClass == "DRUID" or playerClass == "SHAMAN" or playerClass == "PALADIN" or
       playerClass == "MONK" or playerClass == "EVOKER" then
        if groupFormation == GROUP_FORMATION_RAID then
            return true
        end
    end
    
    return false
}

-- Return the module
return GroupRoleManager