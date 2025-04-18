------------------------------------------
-- WindrunnerRotations - Trinket Manager
-- Author: VortexQ8
-- The War Within Season 2
------------------------------------------

local addonName, WR = ...
local TrinketManager = {}
WR.TrinketManager = TrinketManager

-- Dependencies
local API = WR.API
local ConfigRegistry = WR.ConfigRegistry
local ModuleManager = WR.ModuleManager
local MachineLearning = WR.MachineLearning
local GroupRoleManager = WR.GroupRoleManager

-- Data storage
local equippedTrinkets = {}
local trinketData = {}
local playerClass = nil
local playerSpec = nil
local trinketCooldowns = {}
local lastTrinketUsage = {}
local TRINKET_SLOT_1 = 13
local TRINKET_SLOT_2 = 14
local trinketHistory = {}
local trinketClassification = {}
local onUseTrinkets = {}
local procTrinkets = {}
local passiveTrinkets = {}
local trinketEffects = {}
local activeTrinketEffects = {}
local conditionalTrinkets = {}
local raidEncounterPhases = {}
local MAX_HISTORY_ENTRIES = 50
local debugMode = false
local knownStats = {}
local currentBossID = nil
local isInBurst = false
local burstStart = 0
local burstDuration = 15 -- Default burst window duration in seconds
local cooldownsActive = {}
local trinketUsagePreference = {}
local trinketSyncWithCooldowns = {}
local trinketLastSimVal = {}
local maxDPSTrinketCombination = {}
local trinketBlacklist = {}
local trinketShareInformation = {}
local currentInstance = nil
local currentDifficulty = nil

-- Trinket types
local TRINKET_TYPE_DAMAGE = "damage"
local TRINKET_TYPE_HEALING = "healing"
local TRINKET_TYPE_TANK = "tank"
local TRINKET_TYPE_STAT = "stat"
local TRINKET_TYPE_UTILITY = "utility"
local TRINKET_TYPE_AOE = "aoe"
local TRINKET_TYPE_CLEAVE = "cleave"
local TRINKET_TYPE_ST = "single_target"
local TRINKET_TYPE_PVP = "pvp"
local TRINKET_TYPE_MIXED = "mixed"

-- TIer classifications
local TIER_S = "S"
local TIER_A = "A"
local TIER_B = "B"
local TIER_C = "C"
local TIER_D = "D"

-- Initialize the Trinket Manager
function TrinketManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize trinket database
    self:InitializeTrinketDatabase()
    
    -- Update player info
    self:UpdatePlayerInfo()
    
    -- Scan equipped trinkets
    self:ScanEquippedTrinkets()
    
    -- Classify equipped trinkets
    self:ClassifyEquippedTrinkets()
    
    API.PrintDebug("Trinket Manager initialized")
    return true
end

-- Register settings
function TrinketManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("TrinketManager", {
        generalSettings = {
            enableTrinketOptimization = {
                displayName = "Enable Trinket Optimization",
                description = "Automatically optimize trinket usage",
                type = "toggle",
                default = true
            },
            trinketUsageMode = {
                displayName = "Trinket Usage Mode",
                description = "How to use trinkets",
                type = "dropdown",
                options = {"Auto", "On Cooldown", "With Burst", "Situational", "Manual Only"},
                default = "Auto"
            },
            trinketPriority = {
                displayName = "Trinket Priority",
                description = "Priority for trinket usage (higher = use more often)",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 8
            },
            preferedTrinketSlot = {
                displayName = "Preferred Trinket Slot",
                description = "Preferred trinket slot to use first",
                type = "dropdown",
                options = {"Top Trinket", "Bottom Trinket", "Higher Item Level", "Highest Damage", "Auto"},
                default = "Auto"
            }
        },
        cooldownSettings = {
            alignWithBurst = {
                displayName = "Align With Burst",
                description = "Align trinket usage with burst windows",
                type = "toggle",
                default = true
            },
            holdForCooldownPhase = {
                displayName = "Hold for Cooldown Phase",
                description = "Hold trinkets for cooldown phases in boss fights",
                type = "toggle",
                default = true
            },
            holdForBossAbilities = {
                displayName = "Hold for Boss Abilities",
                description = "Hold trinkets for specific boss abilities",
                type = "toggle",
                default = true
            },
            holdOnTarget = {
                displayName = "Target Health Hold",
                description = "Hold trinkets for enemies above this health percentage",
                type = "slider",
                min = 0,
                max = 100,
                step = 5,
                default = 80
            }
        },
        onUseTrinketSettings = {
            onUseMode = {
                displayName = "On-Use Trinket Mode",
                description = "How to use on-use trinkets",
                type = "dropdown",
                options = {"Optimized", "On Cooldown", "With Major Cooldowns", "Manual Only"},
                default = "Optimized"
            },
            preferStatTrinkets = {
                displayName = "Prefer Stat Trinkets",
                description = "Prefer trinkets that provide stat buffs",
                type = "toggle",
                default = true
            },
            onUsePriority = {
                displayName = "On-Use Priority",
                description = "Priority for on-use trinket usage",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 7
            },
            useBothTrinkets = {
                displayName = "Use Both Trinkets",
                description = "Use both trinkets in burst windows if possible",
                type = "toggle",
                default = true
            }
        },
        procTrinketSettings = {
            procAwareness = {
                displayName = "Proc Awareness",
                description = "Be aware of trinket procs and adapt",
                type = "toggle",
                default = true
            },
            adaptToProcBuffs = {
                displayName = "Adapt to Proc Buffs",
                description = "Adapt rotation based on trinket procs",
                type = "toggle",
                default = true
            },
            procTrackingPriority = {
                displayName = "Proc Tracking Priority",
                description = "Priority for tracking procs (higher = track more carefully)",
                type = "slider",
                min = 1,
                max = 10,
                step = 1,
                default = 6
            },
            holdForProcAlignment = {
                displayName = "Hold for Proc Alignment",
                description = "Hold abilities for proc alignment",
                type = "toggle",
                default = true
            }
        },
        encounterSettings = {
            encounterSpecificUsage = {
                displayName = "Encounter-Specific Usage",
                description = "Use trinkets differently based on encounter",
                type = "toggle",
                default = true
            },
            adaptToEncounterPhase = {
                displayName = "Adapt to Encounter Phase",
                description = "Adapt trinket usage to different encounter phases",
                type = "toggle",
                default = true
            },
            holdForAOEPhases = {
                displayName = "Hold for AOE Phases",
                description = "Hold AOE trinkets for AOE phases",
                type = "toggle",
                default = true
            },
            prioritizeBossEncounters = {
                displayName = "Prioritize Boss Encounters",
                description = "Prioritize trinket optimization for boss encounters",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Register for events
function TrinketManager:RegisterEvents()
    -- Register for equipment changes
    API.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function(slot)
        if slot == TRINKET_SLOT_1 or slot == TRINKET_SLOT_2 then
            self:OnTrinketChanged(slot)
        end
    end)
    
    -- Register for item cooldown updates
    API.RegisterEvent("ITEM_COOLDOWN_UPDATE", function(itemID)
        self:OnItemCooldownUpdate(itemID)
    end)
    
    -- Register for player entering combat
    API.RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnEnterCombat()
    end)
    
    -- Register for player leaving combat
    API.RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnLeaveCombat()
    end)
    
    -- Register for aura changes to track trinket procs
    API.RegisterEvent("UNIT_AURA", function(unit)
        if unit == "player" then
            self:OnPlayerAuraChanged()
        end
    end)
    
    -- Register for spec change
    API.RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(unit)
        if unit == "player" then
            self:OnSpecializationChanged()
        end
    end)
    
    -- Register for zone changed to track instances
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        self:OnZoneChanged()
    end)
    
    -- Register for encounter start
    API.RegisterEvent("ENCOUNTER_START", function(encounterID, encounterName, difficultyID, groupSize)
        self:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    end)
    
    -- Register for encounter end
    API.RegisterEvent("ENCOUNTER_END", function(encounterID, encounterName, difficultyID, groupSize, success)
        self:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    end)
    
    -- Register for combat log events to track trinket usage
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
}

-- Initialize trinket database
function TrinketManager:InitializeTrinketDatabase()
    trinketData = {
        -- Season 2 War Within (10.2) Raid Trinkets
        [203729] = { name = "Pip's Emerald Friendship Badge", itemLevel = 424, type = TRINKET_TYPE_STAT, tier = TIER_A, 
                    onUse = true, cooldown = 90, mainStat = true, secondaryStat = "versatility", 
                    bestFor = { "DPS", "HEALER", "TANK" } },
        [203963] = { name = "Igneous Flow", itemLevel = 424, type = TRINKET_TYPE_DAMAGE, tier = TIER_S, 
                    onUse = true, cooldown = 90, damage = "physical", 
                    bestFor = { "DPS-Physical" } },
        [204166] = { name = "Irideus Fragment", itemLevel = 424, type = TRINKET_TYPE_STAT, tier = TIER_A, 
                    proc = true, stat = "versatility", 
                    bestFor = { "DPS-Magic", "HEALER", "TANK" } },
        [204201] = { name = "Razorwind Talisman", itemLevel = 424, type = TRINKET_TYPE_DAMAGE, tier = TIER_B, 
                    onUse = false, proc = true, damage = "physical", cleave = true, 
                    bestFor = { "DPS-Physical" } },
        [204211] = { name = "Smoldering Seedling", itemLevel = 424, type = TRINKET_TYPE_DAMAGE, tier = TIER_A, 
                    onUse = true, cooldown = 120, damage = "fire", aoe = true, 
                    bestFor = { "DPS-Magic" } },
        
        -- Mythic+ Trinkets
        [202617] = { name = "Dragonfire Bomb Dispenser", itemLevel = 424, type = TRINKET_TYPE_DAMAGE, tier = TIER_B, 
                    onUse = true, cooldown = 120, damage = "fire", aoe = true, 
                    bestFor = { "DPS" } },
        [203963] = { name = "Pocket Darkflame Ember", itemLevel = 424, type = TRINKET_TYPE_DAMAGE, tier = TIER_S, 
                    onUse = true, cooldown = 90, damage = "shadow", 
                    bestFor = { "DPS-Magic" } },
        [203719] = { name = "Vessel of Searing Shadow", itemLevel = 424, type = TRINKET_TYPE_DAMAGE, tier = TIER_B, 
                    onUse = false, proc = true, damage = "shadow", 
                    bestFor = { "DPS-Magic" } },
        [203992] = { name = "Accelerating Sandglass", itemLevel = 424, type = TRINKET_TYPE_STAT, tier = TIER_A, 
                    onUse = true, cooldown = 60, haste = true, 
                    bestFor = { "DPS", "HEALER" } },
        [202612] = { name = "Spoils of Neltharus", itemLevel = 424, type = TRINKET_TYPE_STAT, tier = TIER_B, 
                    onUse = false, proc = true, randomStat = true, 
                    bestFor = { "DPS", "HEALER", "TANK" } },
        
        -- Tank Trinkets
        [203996] = { name = "Inexorable Force of the Mountain", itemLevel = 424, type = TRINKET_TYPE_TANK, tier = TIER_S, 
                    onUse = true, cooldown = 120, absorb = true, 
                    bestFor = { "TANK" } },
        [203670] = { name = "Augment Stone: Earthwinds", itemLevel = 424, type = TRINKET_TYPE_TANK, tier = TIER_A, 
                    onUse = false, passive = true, avoidance = true, 
                    bestFor = { "TANK" } },
        [194307] = { name = "Tome of Unstable Power", itemLevel = 424, type = TRINKET_TYPE_TANK, tier = TIER_C, 
                    onUse = true, cooldown = 120, versatility = true, 
                    bestFor = { "TANK" } },
        
        -- Healer Trinkets
        [203699] = { name = "Seed of Disruptive Growth", itemLevel = 424, type = TRINKET_TYPE_HEALING, tier = TIER_S, 
                    onUse = true, cooldown = 90, healing = "hot", aoe = true, 
                    bestFor = { "HEALER" } },
        [204170] = { name = "Emerald Censer", itemLevel = 424, type = TRINKET_TYPE_HEALING, tier = TIER_A, 
                    onUse = false, proc = true, healing = "direct", 
                    bestFor = { "HEALER" } },
        [203996] = { name = "Verdant Cypher", itemLevel = 424, type = TRINKET_TYPE_HEALING, tier = TIER_B, 
                    onUse = true, cooldown = 180, healing = "channeled", aoe = true, 
                    bestFor = { "HEALER" } },
        
        -- PvP Trinkets
        [201931] = { name = "Draconic Medallion", itemLevel = 424, type = TRINKET_TYPE_PVP, tier = TIER_S, 
                    onUse = true, cooldown = 120, cc_break = true, 
                    bestFor = { "DPS", "HEALER", "TANK" } },
        [204400] = { name = "Darkmoon Deck Box: Wraith", itemLevel = 424, type = TRINKET_TYPE_PVP, tier = TIER_A, 
                    onUse = true, cooldown = 90, damage = "shadow", cc = true, 
                    bestFor = { "DPS-Magic" } },
        [204999] = { name = "Obsidian Combatant's Badge", itemLevel = 424, type = TRINKET_TYPE_PVP, tier = TIER_A, 
                    onUse = true, cooldown = 90, versatility = true, 
                    bestFor = { "DPS", "HEALER", "TANK" } }
    }
    
    -- Initialize trinket classification
    self:InitializeTrinketClassification()
}

-- Initialize trinket classification
function TrinketManager:InitializeTrinketClassification()
    -- Clear existing classification
    trinketClassification = {}
    
    -- Categorize trinkets by role, class, and spec
    for itemID, data in pairs(trinketData) do
        -- Determine best role for this trinket
        local roleCategory = nil
        if data.type == TRINKET_TYPE_DAMAGE then
            roleCategory = "DPS"
        elseif data.type == TRINKET_TYPE_HEALING then
            roleCategory = "HEALER"
        elseif data.type == TRINKET_TYPE_TANK then
            roleCategory = "TANK"
        else
            -- For utility or stat trinkets, check bestFor field
            if data.bestFor then
                for _, role in ipairs(data.bestFor) do
                    if role == "DPS" or role == "DPS-Magic" or role == "DPS-Physical" then
                        roleCategory = "DPS"
                        break
                    elseif role == "HEALER" then
                        roleCategory = "HEALER"
                        break
                    elseif role == "TANK" then
                        roleCategory = "TANK"
                        break
                    end
                end
            end
        end
        
        -- Fallback if no role category determined
        roleCategory = roleCategory or "ALL"
        
        -- Initialize category if needed
        if not trinketClassification[roleCategory] then
            trinketClassification[roleCategory] = {}
        end
        
        -- Sort by tier and type
        local tierKey = data.tier or TIER_C
        if not trinketClassification[roleCategory][tierKey] then
            trinketClassification[roleCategory][tierKey] = {}
        end
        
        -- Add to classification
        trinketClassification[roleCategory][tierKey][itemID] = data
        
        -- Add to on-use, proc, or passive lists
        if data.onUse then
            onUseTrinkets[itemID] = data
        elseif data.proc then
            procTrinkets[itemID] = data
        elseif data.passive then
            passiveTrinkets[itemID] = data
        end
        
        -- Add to AOE, cleave, or ST lists
        if data.aoe then
            -- AOE trinket
            if not conditionalTrinkets.aoe then
                conditionalTrinkets.aoe = {}
            end
            conditionalTrinkets.aoe[itemID] = data
        elseif data.cleave then
            -- Cleave trinket
            if not conditionalTrinkets.cleave then
                conditionalTrinkets.cleave = {}
            end
            conditionalTrinkets.cleave[itemID] = data
        end
    end
}

-- Update player info
function TrinketManager:UpdatePlayerInfo()
    -- Get player class and spec
    playerClass = select(2, UnitClass("player"))
    playerSpec = API.GetActiveSpecID()
    
    -- Determine player role based on spec
    local playerRole = self:DeterminePlayerRole()
    
    -- Update trinket usage preference based on role
    self:UpdateTrinketUsagePreference(playerRole)
    
    API.PrintDebug("Player info updated: Class = " .. playerClass .. ", Spec = " .. (playerSpec or "Unknown") .. ", Role = " .. playerRole)
}

-- Determine player role
function TrinketManager:DeterminePlayerRole()
    -- Try to get role from GroupRoleManager
    if WR.GroupRoleManager then
        local role = WR.GroupRoleManager:GetPlayerRole()
        if role == "TANK" then
            return "TANK"
        elseif role == "HEALER" then
            return "HEALER"
        else
            return "DPS"
        end
    end
    
    -- Fallback to spec-based role detection
    local tankSpecs = {
        ["WARRIOR"] = {3}, -- Protection
        ["PALADIN"] = {2}, -- Protection
        ["DRUID"] = {3},   -- Guardian
        ["MONK"] = {1},    -- Brewmaster
        ["DEATHKNIGHT"] = {1}, -- Blood
        ["DEMONHUNTER"] = {2}  -- Vengeance
    }
    
    local healerSpecs = {
        ["PRIEST"] = {1, 2}, -- Discipline, Holy
        ["PALADIN"] = {1},   -- Holy
        ["DRUID"] = {4},     -- Restoration
        ["MONK"] = {2},      -- Mistweaver
        ["SHAMAN"] = {3},    -- Restoration
        ["EVOKER"] = {2}     -- Preservation
    }
    
    if tankSpecs[playerClass] and playerSpec and tContains(tankSpecs[playerClass], playerSpec) then
        return "TANK"
    elseif healerSpecs[playerClass] and playerSpec and tContains(healerSpecs[playerClass], playerSpec) then
        return "HEALER"
    else
        return "DPS"
    end
}

-- Update trinket usage preference
function TrinketManager:UpdateTrinketUsagePreference(role)
    -- Clear existing preference
    trinketUsagePreference = {}
    
    -- Set preference based on role
    if role == "TANK" then
        trinketUsagePreference = {
            primaryType = TRINKET_TYPE_TANK,
            secondaryType = TRINKET_TYPE_STAT,
            damageValue = 0.3, -- Tanks value damage less
            survivalValue = 1.0,
            cooldownValue = 0.8, -- Tanks prefer shorter cooldowns
            tierMultiplier = {
                [TIER_S] = 1.5,
                [TIER_A] = 1.3,
                [TIER_B] = 1.0,
                [TIER_C] = 0.7,
                [TIER_D] = 0.5
            }
        }
    elseif role == "HEALER" then
        trinketUsagePreference = {
            primaryType = TRINKET_TYPE_HEALING,
            secondaryType = TRINKET_TYPE_STAT,
            damageValue = 0.2, -- Healers value damage even less
            survivalValue = 0.8,
            cooldownValue = 0.6, -- Healers prefer shorter cooldowns
            tierMultiplier = {
                [TIER_S] = 1.5,
                [TIER_A] = 1.3,
                [TIER_B] = 1.0,
                [TIER_C] = 0.7,
                [TIER_D] = 0.5
            }
        }
    else -- DPS
        trinketUsagePreference = {
            primaryType = TRINKET_TYPE_DAMAGE,
            secondaryType = TRINKET_TYPE_STAT,
            damageValue = 1.0, -- DPS fully value damage
            survivalValue = 0.3,
            cooldownValue = 0.4, -- DPS can handle longer cooldowns
            tierMultiplier = {
                [TIER_S] = 1.5,
                [TIER_A] = 1.3,
                [TIER_B] = 1.0,
                [TIER_C] = 0.7,
                [TIER_D] = 0.5
            }
        }
    end
}

-- Scan equipped trinkets
function TrinketManager:ScanEquippedTrinkets()
    -- Clear existing data
    equippedTrinkets = {}
    
    -- Scan trinket slot 1
    local itemID1, itemName1, itemLink1, itemIlvl1, itemEquipLoc1 = self:GetSlotInfo(TRINKET_SLOT_1)
    
    if itemID1 and itemID1 > 0 then
        equippedTrinkets[TRINKET_SLOT_1] = {
            itemID = itemID1,
            name = itemName1,
            link = itemLink1,
            ilvl = itemIlvl1,
            cooldown = 0,
            cdRemaining = 0,
            onUse = self:IsOnUseTrinket(itemID1),
            usable = true,
            data = trinketData[itemID1] or {}
        }
        
        -- Update cooldown info
        self:UpdateTrinketCooldown(TRINKET_SLOT_1)
    end
    
    -- Scan trinket slot 2
    local itemID2, itemName2, itemLink2, itemIlvl2, itemEquipLoc2 = self:GetSlotInfo(TRINKET_SLOT_2)
    
    if itemID2 and itemID2 > 0 then
        equippedTrinkets[TRINKET_SLOT_2] = {
            itemID = itemID2,
            name = itemName2,
            link = itemLink2,
            ilvl = itemIlvl2,
            cooldown = 0,
            cdRemaining = 0,
            onUse = self:IsOnUseTrinket(itemID2),
            usable = true,
            data = trinketData[itemID2] or {}
        }
        
        -- Update cooldown info
        self:UpdateTrinketCooldown(TRINKET_SLOT_2)
    end
    
    API.PrintDebug("Equipped trinkets scanned: " .. 
                  (equippedTrinkets[TRINKET_SLOT_1] and equippedTrinkets[TRINKET_SLOT_1].name or "None") .. ", " .. 
                  (equippedTrinkets[TRINKET_SLOT_2] and equippedTrinkets[TRINKET_SLOT_2].name or "None"))
}

-- Get slot info
function TrinketManager:GetSlotInfo(slot)
    -- This would call GetInventoryItemID and related functions in a real addon
    -- For implementation simplicity, we'll return placeholder data
    
    if slot == TRINKET_SLOT_1 then
        return 203729, "Pip's Emerald Friendship Badge", "|cffff8000|Hitem:203729::::::::70:265::33:7:7979:8816:8818:8820:9144:1472:8767::::::|h[Pip's Emerald Friendship Badge]|h|r", 424, "INVTYPE_TRINKET"
    elseif slot == TRINKET_SLOT_2 then
        return 203963, "Igneous Flow", "|cffff8000|Hitem:203963::::::::70:265::33:6:7979:7935:8816:8818:9144:8767::::::|h[Igneous Flow]|h|r", 424, "INVTYPE_TRINKET"
    end
    
    return nil, nil, nil, nil, nil
end

-- Update trinket cooldown
function TrinketManager:UpdateTrinketCooldown(slot)
    if not equippedTrinkets[slot] then
        return
    end
    
    -- Get item cooldown
    local start, duration, enable = GetItemCooldown(equippedTrinkets[slot].itemID)
    
    if start and duration then
        equippedTrinkets[slot].cooldown = duration
        
        if start > 0 then
            equippedTrinkets[slot].cdRemaining = start + duration - GetTime()
        else
            equippedTrinkets[slot].cdRemaining = 0
        end
        
        equippedTrinkets[slot].usable = (equippedTrinkets[slot].cdRemaining <= 0) and enable == 1
    end
}

-- Is on-use trinket
function TrinketManager:IsOnUseTrinket(itemID)
    -- Check known on-use list
    if onUseTrinkets[itemID] then
        return true
    end
    
    -- Check trinket data
    if trinketData[itemID] and trinketData[itemID].onUse then
        return true
    end
    
    -- Get item spell ID
    local _, spellID = GetItemSpell(itemID)
    
    return spellID ~= nil
}

-- Classify equipped trinkets
function TrinketManager:ClassifyEquippedTrinkets()
    for slot, trinket in pairs(equippedTrinkets) do
        -- Skip if already classified in trinket data
        if trinketData[trinket.itemID] then
            API.PrintDebug("Trinket " .. trinket.name .. " already classified in database")
            goto continue
        end
        
        -- Get item spell ID
        local _, spellID = GetItemSpell(trinket.itemID)
        
        -- Determine if it's an on-use trinket
        local isOnUse = spellID ~= nil
        
        -- Classify type based on item name and tooltip
        local trinketType = self:ClassifyTrinketType(trinket.itemID, trinket.name)
        
        -- Store in trinket data
        trinketData[trinket.itemID] = {
            name = trinket.name,
            itemLevel = trinket.ilvl,
            type = trinketType,
            tier = TIER_C, -- Default to C tier for unknown trinkets
            onUse = isOnUse,
            cooldown = isOnUse and self:GetTrinketCooldown(trinket.itemID) or 0,
            bestFor = { self:DeterminePlayerRole() } -- Assume it's good for current role
        }
        
        -- Update trinket
        trinket.data = trinketData[trinket.itemID]
        trinket.onUse = isOnUse
        
        -- Update classification
        self:InitializeTrinketClassification()
        
        ::continue::
    end
}

-- Classify trinket type
function TrinketManager:ClassifyTrinketType(itemID, itemName)
    -- Check tooltip for clues about trinket type
    -- For implementation simplicity, we'll use some naming patterns
    
    local itemName = string.lower(itemName)
    
    -- Damage trinkets
    if string.find(itemName, "igneous") or 
       string.find(itemName, "flame") or 
       string.find(itemName, "damage") or 
       string.find(itemName, "claw") or 
       string.find(itemName, "blast") then
        return TRINKET_TYPE_DAMAGE
    end
    
    -- Healing trinkets
    if string.find(itemName, "heal") or 
       string.find(itemName, "life") or 
       string.find(itemName, "regenerat") or 
       string.find(itemName, "vitality") or 
       string.find(itemName, "renewal") then
        return TRINKET_TYPE_HEALING
    end
    
    -- Tank trinkets
    if string.find(itemName, "shield") or 
       string.find(itemName, "protect") or 
       string.find(itemName, "guard") or 
       string.find(itemName, "bastion") or 
       string.find(itemName, "absorb") then
        return TRINKET_TYPE_TANK
    end
    
    -- Stat trinkets
    if string.find(itemName, "badge") or 
       string.find(itemName, "emblem") or 
       string.find(itemName, "stat") or 
       string.find(itemName, "might") or 
       string.find(itemName, "power") then
        return TRINKET_TYPE_STAT
    end
    
    -- Utility trinkets
    if string.find(itemName, "speed") or 
       string.find(itemName, "movement") or 
       string.find(itemName, "teleport") or 
       string.find(itemName, "blink") then
        return TRINKET_TYPE_UTILITY
    end
    
    -- Default to mixed type
    return TRINKET_TYPE_MIXED
end

-- Get trinket cooldown
function TrinketManager:GetTrinketCooldown(itemID)
    -- Check if we have data for this trinket
    if trinketData[itemID] and trinketData[itemID].cooldown then
        return trinketData[itemID].cooldown
    end
    
    -- For new trinkets, we'd check item cooldown
    local start, duration = GetItemCooldown(itemID)
    
    if duration and duration > 0 then
        return duration
    end
    
    -- Default cooldown
    return 120
end

-- On trinket changed
function TrinketManager:OnTrinketChanged(slot)
    -- Rescan equipped trinkets
    self:ScanEquippedTrinkets()
    
    -- Reclassify trinkets if needed
    self:ClassifyEquippedTrinkets()
    
    -- Update sync with cooldowns
    self:UpdateTrinketSyncWithCooldowns()
    
    API.PrintDebug("Trinket changed in slot " .. slot)
}

-- On item cooldown update
function TrinketManager:OnItemCooldownUpdate(itemID)
    -- Check if this is one of our equipped trinkets
    for slot, trinket in pairs(equippedTrinkets) do
        if trinket.itemID == itemID then
            self:UpdateTrinketCooldown(slot)
            break
        end
    end
}

-- On enter combat
function TrinketManager:OnEnterCombat()
    -- Reset trinket usage for this combat
    lastTrinketUsage = {}
    
    -- Update cooldowns
    for slot, _ in pairs(equippedTrinkets) do
        self:UpdateTrinketCooldown(slot)
    end
    
    -- Reset active trinket effects
    activeTrinketEffects = {}
}

-- On leave combat
function TrinketManager:OnLeaveCombat()
    -- Update cooldowns
    for slot, _ in pairs(equippedTrinkets) do
        self:UpdateTrinketCooldown(slot)
    end
    
    -- Reset active trinket effects
    activeTrinketEffects = {}
    
    -- Reset burst tracking
    isInBurst = false
}

-- On player aura changed
function TrinketManager:OnPlayerAuraChanged()
    -- Check for trinket procs/buffs
    self:CheckTrinketProcs()
}

-- On specialization changed
function TrinketManager:OnSpecializationChanged()
    -- Update player info
    self:UpdatePlayerInfo()
    
    -- Update trinket sync with cooldowns
    self:UpdateTrinketSyncWithCooldowns()
}

-- On zone changed
function TrinketManager:OnZoneChanged()
    -- Check instance info
    local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    
    currentInstance = instanceID
    currentDifficulty = difficultyID
    
    -- Reset boss ID when changing zones
    currentBossID = nil
}

-- On encounter start
function TrinketManager:OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
    currentBossID = encounterID
    
    -- Load encounter-specific data if available
    if raidEncounterPhases[encounterID] then
        API.PrintDebug("Loaded encounter data for " .. encounterName)
    else
        API.PrintDebug("No encounter data for " .. encounterName)
    end
}

-- On encounter end
function TrinketManager:OnEncounterEnd(encounterID, encounterName, difficultyID, groupSize, success)
    currentBossID = nil
}

-- Process combat log event
function TrinketManager:ProcessCombatLogEvent(...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName = ...
    
    -- Only process player events
    if sourceGUID ~= UnitGUID("player") then
        return
    end
    
    -- Track trinket usage
    if event == "SPELL_CAST_SUCCESS" then
        -- Check if this is a trinket spell
        for slot, trinket in pairs(equippedTrinkets) do
            local _, trinketSpellID = GetItemSpell(trinket.itemID)
            
            if trinketSpellID and trinketSpellID == spellID then
                -- Record usage
                self:RecordTrinketUsage(trinket.itemID, GetTime())
                break
            end
        end
    end
    
    -- Track trinket damage or healing
    if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL" then
        -- Check if this is a trinket spell
        -- For implementation simplicity, we'll skip the detailed damage tracking
    end
    
    -- Track cooldown usage
    if event == "SPELL_CAST_SUCCESS" then
        -- Check if this is a major cooldown
        if self:IsMajorCooldown(spellID) then
            -- Record cooldown usage
            cooldownsActive[spellID] = GetTime()
            
            -- Check if this is a burst cooldown
            if self:IsBurstCooldown(spellID) then
                self:StartBurstWindow(spellID)
            end
        end
    end
}

-- Record trinket usage
function TrinketManager:RecordTrinketUsage(itemID, timestamp)
    -- Add to last usage
    lastTrinketUsage[itemID] = timestamp
    
    -- Add to history
    table.insert(trinketHistory, {
        itemID = itemID,
        timestamp = timestamp,
        inBurst = isInBurst,
        activeCooldowns = self:GetActiveCooldowns(),
        targetGUID = UnitGUID("target"),
        targetHealthPct = UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target") * 100) or 0,
        bossID = currentBossID
    })
    
    -- Trim history if needed
    if #trinketHistory > MAX_HISTORY_ENTRIES then
        table.remove(trinketHistory, 1)
    end
    
    -- Update cooldowns
    for slot, trinket in pairs(equippedTrinkets) do
        if trinket.itemID == itemID then
            self:UpdateTrinketCooldown(slot)
            break
        end
    end
}

-- Check trinket procs
function TrinketManager:CheckTrinketProcs()
    -- Scan auras for trinket proc buffs
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
              nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer = UnitBuff("player", i)
        
        if not name then
            break
        end
        
        -- Check if this is a tracked trinket effect
        if trinketEffects[spellID] then
            -- Record proc
            activeTrinketEffects[spellID] = {
                name = name,
                expirationTime = expirationTime,
                duration = duration,
                itemID = trinketEffects[spellID].itemID,
                type = trinketEffects[spellID].type,
                value = trinketEffects[spellID].value
            }
            
            -- Update the rotation priority based on proc
            if trinketEffects[spellID].type == "stat" then
                API.PrintDebug("Trinket proc detected: " .. name .. " (stat)")
            elseif trinketEffects[spellID].type == "damage" then
                API.PrintDebug("Trinket proc detected: " .. name .. " (damage)")
            end
        end
    end
}

-- Start burst window
function TrinketManager:StartBurstWindow(spellID)
    isInBurst = true
    burstStart = GetTime()
    burstDuration = self:GetCooldownBurstDuration(spellID)
    
    API.PrintDebug("Burst window started from " .. GetSpellInfo(spellID) .. " for " .. burstDuration .. " seconds")
    
    -- Consider using trinkets if burst window has started
    self:ConsiderTrinketsForBurst()
    
    -- Schedule end of burst window
    C_Timer.After(burstDuration, function()
        isInBurst = false
        API.PrintDebug("Burst window ended")
    end)
}

-- Get cooldown burst duration
function TrinketManager:GetCooldownBurstDuration(spellID)
    -- Get burst duration for specific cooldowns
    local burstDurations = {
        -- Mage
        [12472] = 20, -- Icy Veins
        [190319] = 10, -- Combustion
        
        -- Warrior
        [1719] = 10, -- Recklessness
        
        -- Paladin
        [31884] = 20, -- Avenging Wrath
        
        -- Druid
        [194223] = 20, -- Celestial Alignment
        
        -- Default
        [0] = 15
    }
    
    return burstDurations[spellID] or burstDurations[0]
}

-- Get active cooldowns
function TrinketManager:GetActiveCooldowns()
    local active = {}
    local now = GetTime()
    
    for spellID, startTime in pairs(cooldownsActive) do
        -- Check if cooldown is still active
        local duration = self:GetCooldownDuration(spellID)
        if now - startTime <= duration then
            active[spellID] = {
                name = GetSpellInfo(spellID),
                remaining = duration - (now - startTime)
            }
        end
    end
    
    return active
}

-- Get cooldown duration
function TrinketManager:GetCooldownDuration(spellID)
    -- Simplified duration lookup
    local cooldownDurations = {
        -- Mage
        [12472] = 20, -- Icy Veins
        [190319] = 10, -- Combustion
        
        -- Warrior
        [1719] = 10, -- Recklessness
        
        -- Paladin
        [31884] = 20, -- Avenging Wrath
        
        -- Druid
        [194223] = 20, -- Celestial Alignment
        
        -- Default
        [0] = 15
    }
    
    return cooldownDurations[spellID] or cooldownDurations[0]
}

-- Is major cooldown
function TrinketManager:IsMajorCooldown(spellID)
    -- Check major cooldowns by class
    local majorCooldowns = {
        ["MAGE"] = {12472, 190319, 12042}, -- Icy Veins, Combustion, Arcane Power
        ["WARRIOR"] = {1719, 107574}, -- Recklessness, Avatar
        ["PALADIN"] = {31884, 231895}, -- Avenging Wrath, Crusade
        ["DRUID"] = {194223, 102560, 50334}, -- Celestial Alignment, Incarnation: Chosen of Elune, Berserk
        ["PRIEST"] = {10060, 47536, 194249}, -- Power Infusion, Rapture, Voidform
        ["WARLOCK"] = {205180, 113858, 113860}, -- Summon Darkglare, Dark Soul: Instability, Dark Soul: Misery
        ["SHAMAN"] = {114050, 114051, 114052}, -- Ascendance (Ele, Enh, Resto)
        ["HUNTER"] = {193530, 201430, 266779}, -- Aspect of the Wild, Stampede, Coordinated Assault
        ["ROGUE"] = {13750, 121471, 343142}, -- Adrenaline Rush, Shadow Blades, Symbols of Death
        ["DEATHKNIGHT"] = {47568, 275699, 63560}, -- Empower Rune Weapon, Apocalypse, Dark Transformation
        ["MONK"] = {137639, 152173, 115080}, -- Storm, Earth, and Fire, Serenity, Touch of Death
        ["DEMONHUNTER"] = {191427, 187827}, -- Metamorphosis, Metamorphosis (Vengeance)
        ["EVOKER"] = {375087, 370553} -- Dragonrage, Tip the Scales
    }
    
    -- Check if this spell is a major cooldown for the player's class
    if majorCooldowns[playerClass] and tContains(majorCooldowns[playerClass], spellID) then
        return true
    end
    
    return false
}

-- Is burst cooldown
function TrinketManager:IsBurstCooldown(spellID)
    -- Most major cooldowns are also burst cooldowns
    return self:IsMajorCooldown(spellID)
}

-- Consider trinkets for burst
function TrinketManager:ConsiderTrinketsForBurst()
    local settings = ConfigRegistry:GetSettings("TrinketManager")
    
    -- Skip if trinket optimization is disabled
    if not settings.generalSettings.enableTrinketOptimization then
        return
    end
    
    -- Skip if not aligning with burst
    if not settings.cooldownSettings.alignWithBurst then
        return
    end
    
    -- Only proceed if we're in a burst window
    if not isInBurst then
        return
    end
    
    -- Check for on-use trinkets
    for slot, trinket in pairs(equippedTrinkets) do
        -- Skip if not an on-use trinket
        if not trinket.onUse then
            goto continue
        end
        
        -- Skip if on cooldown
        if trinket.cdRemaining > 0 then
            goto continue
        end
        
        -- Consider using this trinket
        if self:ShouldUseTrinketNow(slot) then
            -- Use trinket
            self:UseTrinket(slot)
            
            -- If we don't want to use both trinkets, break after using one
            if not settings.onUseTrinketSettings.useBothTrinkets then
                break
            end
        end
        
        ::continue::
    end
}

-- Update trinket sync with cooldowns
function TrinketManager:UpdateTrinketSyncWithCooldowns()
    -- Clear existing sync
    trinketSyncWithCooldowns = {}
    
    -- Get usable trinkets
    local usableTrinkets = {}
    
    for slot, trinket in pairs(equippedTrinkets) do
        if trinket.onUse then
            table.insert(usableTrinkets, {
                slot = slot,
                itemID = trinket.itemID,
                data = trinket.data
            })
        end
    end
    
    -- Get major cooldowns
    local cooldowns = self:GetClassMajorCooldowns()
    
    -- Match trinkets with cooldowns
    for _, trinket in ipairs(usableTrinkets) do
        local bestCooldown = nil
        local bestScore = 0
        
        for _, cooldown in ipairs(cooldowns) do
            local score = self:GetTrinketCooldownSyncScore(trinket.itemID, cooldown.spellID)
            
            if score > bestScore then
                bestScore = score
                bestCooldown = cooldown.spellID
            end
        end
        
        if bestCooldown then
            trinketSyncWithCooldowns[trinket.itemID] = bestCooldown
        end
    end
}

-- Get class major cooldowns
function TrinketManager:GetClassMajorCooldowns()
    local cooldowns = {}
    
    -- Class-specific cooldowns
    local classCooldowns = {
        ["MAGE"] = {
            {spellID = 12472, name = "Icy Veins", spec = 3}, -- Frost
            {spellID = 190319, name = "Combustion", spec = 2}, -- Fire
            {spellID = 12042, name = "Arcane Power", spec = 1} -- Arcane
        },
        ["WARRIOR"] = {
            {spellID = 1719, name = "Recklessness"}, -- All DPS specs
            {spellID = 107574, name = "Avatar"} -- Arms, Protection
        },
        -- Other classes...
    }
    
    -- Add class cooldowns
    if classCooldowns[playerClass] then
        for _, cooldown in ipairs(classCooldowns[playerClass]) do
            -- Only add for current spec or all specs
            if not cooldown.spec or cooldown.spec == playerSpec then
                table.insert(cooldowns, cooldown)
            end
        end
    end
    
    return cooldowns
}

-- Get trinket cooldown sync score
function TrinketManager:GetTrinketCooldownSyncScore(itemID, spellID)
    -- Calculate how well a trinket syncs with a cooldown
    local score = 0
    
    -- Get trinket data
    local trinketData = trinketData[itemID]
    if not trinketData then
        return 0
    end
    
    -- Get cooldown info
    local cooldownName = GetSpellInfo(spellID)
    if not cooldownName then
        return 0
    end
    
    -- Base score on trinket type
    if trinketData.type == TRINKET_TYPE_DAMAGE then
        score = score + 10 -- Damage trinkets sync well with damage cooldowns
    elseif trinketData.type == TRINKET_TYPE_STAT then
        score = score + 8 -- Stat trinkets also sync well
    elseif trinketData.type == TRINKET_TYPE_MIXED or trinketData.type == TRINKET_TYPE_UTILITY then
        score = score + 5 -- Others are okayish
    end
    
    -- Adjust based on trinket cooldown
    local cdRatio = trinketData.cooldown / self:GetSpellCooldown(spellID)
    
    if cdRatio >= 0.8 and cdRatio <= 1.2 then
        score = score + 5 -- Similar cooldowns
    elseif cdRatio >= 0.5 and cdRatio <= 1.5 then
        score = score + 3 -- Somewhat similar
    end
    
    -- Adjust based on tier
    if trinketData.tier == TIER_S then
        score = score + 4
    elseif trinketData.tier == TIER_A then
        score = score + 3
    elseif trinketData.tier == TIER_B then
        score = score + 2
    elseif trinketData.tier == TIER_C then
        score = score + 1
    end
    
    return score
}

-- Get spell cooldown
function TrinketManager:GetSpellCooldown(spellID)
    -- Get spell cooldown duration
    local start, duration = GetSpellCooldown(spellID)
    
    if duration and duration > 0 then
        return duration
    end
    
    -- Default cooldown durations for some common spells
    local cooldowns = {
        [12472] = 180, -- Icy Veins
        [190319] = 120, -- Combustion
        [12042] = 90, -- Arcane Power
        [1719] = 90, -- Recklessness
        [31884] = 120, -- Avenging Wrath
        [194223] = 180, -- Celestial Alignment
    }
    
    return cooldowns[spellID] or 120 -- Default to 2 minutes
end

-- Should use trinket now
function TrinketManager:ShouldUseTrinketNow(slot)
    local settings = ConfigRegistry:GetSettings("TrinketManager")
    
    -- Skip if trinket optimization is disabled
    if not settings.generalSettings.enableTrinketOptimization then
        return false
    end
    
    -- Get trinket info
    local trinket = equippedTrinkets[slot]
    if not trinket or not trinket.onUse or not trinket.usable then
        return false
    end
    
    -- Check usage mode
    local usageMode = settings.generalSettings.trinketUsageMode
    
    if usageMode == "Manual Only" then
        return false -- User will handle trinkets manually
    elseif usageMode == "On Cooldown" then
        return true -- Use whenever available
    elseif usageMode == "With Burst" then
        return isInBurst -- Only use during burst
    elseif usageMode == "Situational" then
        -- Only use in specific situations
        return self:IsSituationallyAppropriate(slot)
    end
    
    -- Auto mode - make an intelligent decision
    if isInBurst then
        return true -- Use during burst windows
    end
    
    -- Check if we're holding for boss/priority targets
    if settings.cooldownSettings.holdForBossAbilities and currentBossID then
        return false -- Hold for boss
    end
    
    -- Check target health threshold
    if UnitExists("target") and settings.cooldownSettings.holdOnTarget > 0 then
        local healthPct = UnitHealth("target") / UnitHealthMax("target") * 100
        if healthPct > settings.cooldownSettings.holdOnTarget then
            return false -- Hold for lower health
        end
    end
    
    -- For AOE trinkets, check enemy count
    if trinket.data and trinket.data.aoe then
        local enemyCount = self:GetNearbyEnemyCount()
        if enemyCount < 3 then
            return false -- Not enough enemies for AOE trinket
        end
    end
    
    -- Default to using
    return true
}

-- Is situationally appropriate
function TrinketManager:IsSituationallyAppropriate(slot)
    local trinket = equippedTrinkets[slot]
    if not trinket or not trinket.data then
        return true -- If we don't know, just use it
    end
    
    -- Check trinket type
    if trinket.data.type == TRINKET_TYPE_DAMAGE then
        -- For damage trinkets, check if we're in combat and have a target
        return UnitAffectingCombat("player") and UnitExists("target")
    elseif trinket.data.type == TRINKET_TYPE_HEALING then
        -- For healing trinkets, check if anyone needs healing
        return self:IsHealingNeeded()
    elseif trinket.data.type == TRINKET_TYPE_TANK then
        -- For tank trinkets, check if we're taking damage
        return UnitAffectingCombat("player") and self:IsDamageMitigationNeeded()
    elseif trinket.data.type == TRINKET_TYPE_STAT then
        -- For stat trinkets, check if we're in combat
        return UnitAffectingCombat("player")
    elseif trinket.data.type == TRINKET_TYPE_UTILITY then
        -- For utility trinkets, always allow
        return true
    elseif trinket.data.type == TRINKET_TYPE_AOE then
        -- For AOE trinkets, check enemy count
        return self:GetNearbyEnemyCount() >= 3
    elseif trinket.data.type == TRINKET_TYPE_PVP then
        -- For PVP trinkets, check if in PVP or CC'd
        return self:IsInPvP() or self:IsControlImpaired()
    end
    
    return true -- Default to allowing
end

-- Get nearby enemy count
function TrinketManager:GetNearbyEnemyCount()
    -- This would use a proper enemy counting function in a real addon
    return 3 -- Placeholder
end

-- Is healing needed
function TrinketManager:IsHealingNeeded()
    -- Check if player health is below threshold
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    if healthPct < 80 then
        return true
    end
    
    -- Check group members if we're a healer
    if self:DeterminePlayerRole() == "HEALER" and WR.GroupRoleManager and WR.GroupRoleManager:IsInGroup() then
        return true -- For simplicity, assume healing is needed in groups
    end
    
    return false
end

-- Is damage mitigation needed
function TrinketManager:IsDamageMitigationNeeded()
    -- Check if player health is below threshold
    local healthPct = UnitHealth("player") / UnitHealthMax("player") * 100
    if healthPct < 60 then
        return true
    end
    
    return UnitAffectingCombat("player") -- In combat, assume mitigation is useful
end

-- Is in PvP
function TrinketManager:IsInPvP()
    if WR.PvPManager then
        return WR.PvPManager:IsInPvP()
    end
    
    -- Fallback
    return C_PvP.IsArena() or UnitInBattleground("player") or C_PvP.IsWarModeDesired()
end

-- Is control impaired
function TrinketManager:IsControlImpaired()
    -- Check for CCs on player
    for i = 1, 40 do
        local name, _, _, debuffType = UnitDebuff("player", i)
        
        if not name then
            break
        end
        
        -- Check if this is a CC debuff
        if debuffType == "Stun" or debuffType == "Fear" or debuffType == "Charm" or debuffType == "Silence" then
            return true
        end
    end
    
    return false
end

-- Use trinket
function TrinketManager:UseTrinket(slot)
    -- Skip if no trinket in that slot
    if not equippedTrinkets[slot] then
        return false
    end
    
    -- Skip if not usable
    if not equippedTrinkets[slot].usable then
        return false
    end
    
    -- Get target based on trinket type
    local target = self:GetTrinketTarget(slot)
    
    -- Use the trinket
    if target then
        UseItemByName(equippedTrinkets[slot].itemID, target)
    else
        UseItemByName(equippedTrinkets[slot].itemID)
    end
    
    -- Record usage
    self:RecordTrinketUsage(equippedTrinkets[slot].itemID, GetTime())
    
    -- Update cooldown
    self:UpdateTrinketCooldown(slot)
    
    API.PrintDebug("Used trinket: " .. equippedTrinkets[slot].name)
    return true
}

-- Get trinket target
function TrinketManager:GetTrinketTarget(slot)
    local trinket = equippedTrinkets[slot]
    if not trinket or not trinket.data then
        return nil -- Use default targeting
    end
    
    -- Check trinket type
    if trinket.data.type == TRINKET_TYPE_HEALING then
        -- For healing trinkets, find lowest health ally
        return self:GetLowestHealthAlly()
    elseif trinket.data.type == TRINKET_TYPE_DAMAGE then
        -- For damage trinkets, use on current target
        return UnitExists("target") and "target" or nil
    end
    
    return nil -- Use default targeting
end

-- Get lowest health ally
function TrinketManager:GetLowestHealthAlly()
    local lowestUnit = "player"
    local lowestPct = UnitHealth("player") / UnitHealthMax("player") * 100
    
    -- Check party/raid members
    if WR.GroupRoleManager and WR.GroupRoleManager:IsInGroup() then
        local prefix = WR.GroupRoleManager:IsInRaid() and "raid" or "party"
        local count = WR.GroupRoleManager:IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers() - 1
        
        for i = 1, count do
            local unit = prefix .. i
            
            if UnitExists(unit) and UnitIsVisible(unit) and not UnitIsDead(unit) then
                local healthPct = UnitHealth(unit) / UnitHealthMax(unit) * 100
                
                if healthPct < lowestPct then
                    lowestPct = healthPct
                    lowestUnit = unit
                end
            end
        end
    end
    
    return lowestPct < 90 and lowestUnit or nil -- Only return if someone actually needs healing
end

-- Get best trinket slot
function TrinketManager:GetBestTrinketSlot()
    local settings = ConfigRegistry:GetSettings("TrinketManager")
    
    -- Check if we have preferences
    local preferred = settings.generalSettings.preferedTrinketSlot
    
    if preferred == "Top Trinket" then
        return TRINKET_SLOT_1
    elseif preferred == "Bottom Trinket" then
        return TRINKET_SLOT_2
    end
    
    -- Check both trinkets
    if not equippedTrinkets[TRINKET_SLOT_1] and not equippedTrinkets[TRINKET_SLOT_2] then
        return nil -- No trinkets equipped
    elseif not equippedTrinkets[TRINKET_SLOT_1] then
        return TRINKET_SLOT_2 -- Only bottom trinket equipped
    elseif not equippedTrinkets[TRINKET_SLOT_2] then
        return TRINKET_SLOT_1 -- Only top trinket equipped
    end
    
    -- Both trinkets equipped, apply preference
    if preferred == "Higher Item Level" then
        return equippedTrinkets[TRINKET_SLOT_1].ilvl >= equippedTrinkets[TRINKET_SLOT_2].ilvl and TRINKET_SLOT_1 or TRINKET_SLOT_2
    elseif preferred == "Highest Damage" then
        -- In a real addon, this would use damage sims
        if equippedTrinkets[TRINKET_SLOT_1].data and equippedTrinkets[TRINKET_SLOT_2].data then
            local tier1 = equippedTrinkets[TRINKET_SLOT_1].data.tier or TIER_C
            local tier2 = equippedTrinkets[TRINKET_SLOT_2].data.tier or TIER_C
            
            -- Convert tier to numeric value
            local tierValue = {
                [TIER_S] = 5,
                [TIER_A] = 4,
                [TIER_B] = 3,
                [TIER_C] = 2,
                [TIER_D] = 1
            }
            
            return tierValue[tier1] >= tierValue[tier2] and TRINKET_SLOT_1 or TRINKET_SLOT_2
        end
    end
    
    -- Default to top trinket
    return TRINKET_SLOT_1
}

-- Get available trinkets
function TrinketManager:GetAvailableTrinkets()
    local available = {}
    
    for slot, trinket in pairs(equippedTrinkets) do
        if trinket.usable and trinket.onUse then
            table.insert(available, {
                slot = slot,
                itemID = trinket.itemID,
                name = trinket.name,
                data = trinket.data
            })
        end
    end
    
    return available
}

-- Get top performance trinket
function TrinketManager:GetTopPerformanceTrinket()
    -- This would use item level + tier + role appropriateness in a real addon
    local bestSlot = nil
    local bestScore = 0
    
    for slot, trinket in pairs(equippedTrinkets) do
        local score = self:CalculateTrinketPerformanceScore(trinket)
        
        if score > bestScore then
            bestScore = score
            bestSlot = slot
        end
    end
    
    return bestSlot
}

-- Calculate trinket performance score
function TrinketManager:CalculateTrinketPerformanceScore(trinket)
    if not trinket or not trinket.data then
        return 0
    end
    
    local score = 0
    
    -- Base score on item level
    score = trinket.ilvl / 10
    
    -- Adjust based on tier
    local tierMultiplier = {
        [TIER_S] = 1.5,
        [TIER_A] = 1.3,
        [TIER_B] = 1.0,
        [TIER_C] = 0.8,
        [TIER_D] = 0.6
    }
    
    if trinket.data.tier then
        score = score * (tierMultiplier[trinket.data.tier] or 1.0)
    end
    
    -- Adjust based on role appropriateness
    local playerRole = self:DeterminePlayerRole()
    
    if trinket.data.bestFor and tContains(trinket.data.bestFor, playerRole) then
        score = score * 1.2
    end
    
    -- Adjust based on trinket type
    if trinket.data.type == TRINKET_TYPE_DAMAGE and playerRole == "DPS" then
        score = score * 1.2
    elseif trinket.data.type == TRINKET_TYPE_HEALING and playerRole == "HEALER" then
        score = score * 1.2
    elseif trinket.data.type == TRINKET_TYPE_TANK and playerRole == "TANK" then
        score = score * 1.2
    end
    
    return score
end

-- Should track trinket
function TrinketManager:ShouldTrackTrinket(itemID)
    -- Always track equipped trinkets
    for _, trinket in pairs(equippedTrinkets) do
        if trinket.itemID == itemID then
            return true
        end
    end
    
    -- Check if it's a known trinket
    return trinketData[itemID] ~= nil
end

-- Is trinket on blacklist
function TrinketManager:IsTrinketOnBlacklist(itemID)
    return trinketBlacklist[itemID] ~= nil
}

-- Add trinket to blacklist
function TrinketManager:AddTrinketToBlacklist(itemID, reason)
    trinketBlacklist[itemID] = {
        reason = reason or "User blacklisted",
        timestamp = GetTime()
    }
}

-- Remove trinket from blacklist
function TrinketManager:RemoveTrinketFromBlacklist(itemID)
    trinketBlacklist[itemID] = nil
}

-- Get trinket info
function TrinketManager:GetTrinketInfo(itemID)
    return trinketData[itemID]
}

-- Get equipped trinkets
function TrinketManager:GetEquippedTrinkets()
    return equippedTrinkets
}

-- Is in burst
function TrinketManager:IsInBurst()
    return isInBurst
}

-- Get burst time remaining
function TrinketManager:GetBurstTimeRemaining()
    if not isInBurst then
        return 0
    end
    
    local remaining = (burstStart + burstDuration) - GetTime()
    return remaining > 0 and remaining or 0
}

-- Should use trinket
function TrinketManager:ShouldUseTrinket(slot)
    return self:ShouldUseTrinketNow(slot)
}

-- Use best trinket
function TrinketManager:UseBestTrinket()
    local bestSlot = self:GetBestTrinketSlot()
    
    if bestSlot then
        return self:UseTrinket(bestSlot)
    end
    
    return false
}

-- Return the module
return TrinketManager