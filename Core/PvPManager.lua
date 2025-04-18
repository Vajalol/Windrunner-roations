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
local CombatAnalysis = WR.CombatAnalysis

-- PvP data
local isEnabled = true
local pvpFrame = nil
local updateFrequency = 0.1 -- Update PvP data every 0.1 seconds
local lastUpdate = 0
local inArena = false
local inBattleground = false
local inPvP = false
local isRatedBG = false
local isRatedArena = false
local arenaType = nil -- 2v2, 3v3, etc.
local enemyTeam = {}
local friendlyTeam = {}
local arenaEnemies = {}
local arenaAllies = {}
local targetEnemyIndex = nil
local focusEnemyIndex = nil
local enemyHealer = nil
local enemyTank = nil
local enemyDPS = {}
local allyHealer = nil
local targetDR = {}
local enemyDR = {}
local globalDR = {}
local MAX_DR_HISTORY = 50
local pvpVendors = {}
local playerCombatState = {}
local enemyCombatState = {}
local lastBattlegroundUpdate = 0
local BATTLEGROUND_UPDATE_FREQ = 1.0
local diminishingReturns = {
    ["stun"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["incapacitate"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["disorient"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["silence"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["root"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["disarm"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["fear"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["horror"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["mind_control"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["kidney_shot"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["random_stun"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["random_root"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["cyclone"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["dragon_breath"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} },
    ["scatter_shot"] = { duration = 18, multipliers = {1, 0.5, 0.25, 0} }
}
local drCategories = {
    -- Stuns
    [108194] = "stun",       -- Asphyxiate (Unholy)
    [221562] = "stun",       -- Asphyxiate (Blood)
    [91800] = "stun",        -- Gnaw (Ghoul)
    [91797] = "stun",        -- Monstrous Blow (Mutated Ghoul)
    [287254] = "stun",       -- Dead of Winter
    [210141] = "stun",       -- Zombie Explosion
    [334693] = "stun",       -- Absolute Zero (Breath of Sindragosa)
    [205630] = "stun",       -- Illidan's Grasp (Primary effect)
    [208618] = "stun",       -- Illidan's Grasp (Secondary effect)
    [211881] = "stun",       -- Fel Eruption
    [200166] = "stun",       -- Metamorphosis (PvE stun effect)
    [203123] = "stun",       -- Maim
    [163505] = "stun",       -- Rake (Prowl)
    [5211] = "stun",         -- Mighty Bash
    [202244] = "stun",       -- Overrun (Also a knockback)
    [118905] = "stun",       -- Static Charge (Capacitor Totem)
    [118345] = "stun",       -- Pulverize (Primal Earth Elemental)
    [204399] = "stun",       -- Earthfury (PvP talent)
    [179057] = "stun",       -- Chaos Nova
    [132168] = "stun",       -- Shockwave
    [132169] = "stun",       -- Storm Bolt
    [199085] = "stun",       -- Warpath
    [213688] = "stun",       -- Fel Cleave (PvP talent)
    [20549] = "stun",        -- War Stomp (Tauren)
    [255723] = "stun",       -- Bull Rush (Highmountain Tauren)
    [287712] = "stun",       -- Haymaker (Kul Tiran)
    
    -- Incapacitates
    [217832] = "incapacitate",  -- Imprison
    [221527] = "incapacitate",  -- Imprison (PvP talent)
    [99] = "incapacitate",      -- Incapacitating Roar
    [2637] = "incapacitate",    -- Hibernate
    [10326] = "incapacitate",   -- Turn Evil
    [3355] = "incapacitate",    -- Freezing Trap
    [203337] = "incapacitate",  -- Freezing Trap (Honor talent)
    [209790] = "incapacitate",  -- Freezing Arrow
    [213691] = "incapacitate",  -- Scatter Shot
    [118] = "incapacitate",     -- Polymorph
    [28271] = "incapacitate",   -- Polymorph (Turtle)
    [28272] = "incapacitate",   -- Polymorph (Pig)
    [61025] = "incapacitate",   -- Polymorph (Snake)
    [61305] = "incapacitate",   -- Polymorph (Black Cat)
    [61780] = "incapacitate",   -- Polymorph (Turkey)
    [61721] = "incapacitate",   -- Polymorph (Rabbit)
    [126819] = "incapacitate",  -- Polymorph (Porcupine)
    [161353] = "incapacitate",  -- Polymorph (Polar Bear Cub)
    [161354] = "incapacitate",  -- Polymorph (Monkey)
    [161355] = "incapacitate",  -- Polymorph (Penguin)
    [161372] = "incapacitate",  -- Polymorph (Peacock)
    [277787] = "incapacitate",  -- Polymorph (Baby Direhorn)
    [277792] = "incapacitate",  -- Polymorph (Bumblebee)
    [82691] = "incapacitate",   -- Ring of Frost
    [115078] = "incapacitate",  -- Paralysis
    [20066] = "incapacitate",   -- Repentance
    [9484] = "incapacitate",    -- Shackle Undead
    [200196] = "incapacitate",  -- Holy Word: Chastise
    [1776] = "incapacitate",    -- Gouge
    [6770] = "incapacitate",    -- Sap
    [51514] = "incapacitate",   -- Hex
    [196942] = "incapacitate",  -- Hex (Voodoo Totem)
    [210873] = "incapacitate",  -- Hex (Raptor)
    [211004] = "incapacitate",  -- Hex (Spider)
    [211010] = "incapacitate",  -- Hex (Snake)
    [211015] = "incapacitate",  -- Hex (Cockroach)
    [269352] = "incapacitate",  -- Hex (Skeletal Hatchling)
    [277778] = "incapacitate",  -- Hex (Zandalari Tendonripper)
    [277784] = "incapacitate",  -- Hex (Wicker Mongrel)
    [309328] = "incapacitate",  -- Hex (Living Honey)
    [197214] = "incapacitate",  -- Sundering
    [710] = "incapacitate",     -- Banish
    [6789] = "incapacitate",    -- Mortal Coil
    [107079] = "incapacitate",  -- Quaking Palm (Pandaren)
    [89766] = "incapacitate",   -- Axe Toss (Felguard)
    
    -- Disorients
    [31661] = "disorient",     -- Dragon's Breath
    [198909] = "disorient",    -- Song of Chi-Ji
    [202274] = "disorient",    -- Incendiary Brew
    [105421] = "disorient",    -- Blinding Light
    [605] = "disorient",       -- Mind Control
    [8122] = "disorient",      -- Psychic Scream
    [226943] = "disorient",    -- Mind Bomb
    [2094] = "disorient",      -- Blind
    [5246] = "disorient",      -- Intimidating Shout
    [118699] = "disorient",    -- Fear
    [130616] = "disorient",    -- Fear (Glyph of Fear)
    [334275] = "disorient",    -- Curse of Exhaustion
    
    -- Silences
    [204490] = "silence",      -- Sigil of Silence
    [202137] = "silence",      -- Sigil of Silence (Kyrian)
    [207167] = "silence",      -- Blinding Sleet
    [47476] = "silence",       -- Strangulate
    [81261] = "silence",       -- Solar Beam
    [217824] = "silence",      -- Shield of Virtue
    [15487] = "silence",       -- Silence
    [1330] = "silence",        -- Garrote
    [196364] = "silence",      -- Unstable Affliction Silence Effect
    
    -- Roots
    [204085] = "root",        -- Deathchill (PvP talent)
    [198121] = "root",        -- Frostbite
    [235963] = "root",        -- Glacial Presence
    [233395] = "root",        -- Frozen Center
    [339] = "root",           -- Entangling Roots
    [170855] = "root",        -- Entangling Roots (Nature's Grasp)
    [45334] = "root",         -- Immobilized (Wild Charge)
    [102359] = "root",        -- Mass Entanglement
    [122] = "root",           -- Frost Nova
    [33395] = "root",         -- Freeze
    [64695] = "root",         -- Earthgrab
    [117526] = "root",        -- Binding Shot
    [162480] = "root",        -- Steel Trap
    [180275] = "root",        -- Piercing Shot
    [4167] = "root",          -- Web (Spider)
    [199086] = "root",        -- Warpath
    [323673] = "root",        -- Mindgames (Covenant)
    
    -- Disarms
    [209749] = "disarm",      -- Faerie Swarm (PvP talent)
    [207777] = "disarm",      -- Dismantle
    [233759] = "disarm",      -- Grapple Weapon
    [236077] = "disarm",      -- Disarm
    
    -- Special
    [1833] = "kidney_shot",   -- Cheap Shot
    [408] = "kidney_shot",    -- Kidney Shot
    [199804] = "kidney_shot", -- Between the Eyes
    [118699] = "fear",        -- Fear
    [5484] = "fear",          -- Howl of Terror
    [8122] = "fear",          -- Psychic Scream
    [113724] = "fear",        -- Ring of Peace
    [64044] = "horror",       -- Psychic Horror
    [64695] = "random_root",  -- Earthgrab
    [233395] = "random_root", -- Frozen Center
    [198121] = "random_root", -- Frostbite
    [204085] = "random_root", -- Deathchill
    [115268] = "random_stun", -- Mesmerize
    [20549] = "random_stun",  -- War Stomp
    [28730] = "random_stun",  -- Arcane Torrent
    [84369] = "random_stun",  -- Engineer's Gnomish Gravity Well
    [24394] = "random_stun",  -- Intimidation
    [119381] = "random_stun", -- Leg Sweep
    [56222] = "random_stun",  -- Dark Command
    [132168] = "random_stun", -- Shockwave
    [179057] = "random_stun", -- Chaos Nova
    [31661] = "dragon_breath", -- Dragon's Breath
    [33786] = "cyclone",      -- Cyclone
    [19503] = "scatter_shot", -- Scatter Shot
}
local classColors = {
    ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43, hex = "C79C6E"},
    ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73, hex = "F58CBA"},
    ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45, hex = "ABD473"},
    ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41, hex = "FFF569"},
    ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00, hex = "FFFFFF"},
    ["DEATHKNIGHT"] = {r = 0.77, g = 0.12, b = 0.23, hex = "C41F3B"},
    ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87, hex = "0070DE"},
    ["MAGE"] = {r = 0.25, g = 0.78, b = 0.92, hex = "40C7EB"},
    ["WARLOCK"] = {r = 0.53, g = 0.53, b = 0.93, hex = "8787ED"},
    ["MONK"] = {r = 0.00, g = 1.00, b = 0.60, hex = "00FF96"},
    ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04, hex = "FF7D0A"},
    ["DEMONHUNTER"] = {r = 0.64, g = 0.19, b = 0.79, hex = "A330C9"},
    ["EVOKER"] = {r = 0.20, g = 0.58, b = 0.50, hex = "33937F"}
}
local pvpTrinketIDs = {
    [37865] = true,   -- Medallion of the Alliance
    [37864] = true,   -- Medallion of the Horde
    [190460] = true,  -- Gladiator's Medallion
    [214027] = true,  -- Adaptation
    [195710] = true,  -- Honorable Medallion
    [305252] = true,  -- Gladiator's Emblem
    [336126] = true,  -- Gladiator's Medallion (Shadowlands Season 1)
    [336135] = true,  -- Gladiator's Medallion (Shadowlands Season 2)
    [336889] = true,  -- Gladiator's Medallion (Shadowlands Season 3)
    [336998] = true,  -- Gladiator's Medallion (Shadowlands Season 4)
    [345231] = true,  -- Gladiator's Medallion (Dragonflight Season 1)
    [357283] = true,  -- Gladiator's Medallion (Dragonflight Season 2)
    [357414] = true,  -- Gladiator's Medallion (Dragonflight Season 3)
    [357927] = true,  -- Gladiator's Medallion (Dragonflight Season 4)
    [369597] = true,  -- Gladiator's Medallion (The War Within Season 1)
    [374291] = true,  -- Gladiator's Medallion (The War Within Season 2)
}
local pvpCombatMetrics = {
    damageDone = {},
    healingDone = {},
    damageTaken = {},
    healingTaken = {},
    ccApplied = {},
    ccTaken = {},
    interruptsCast = {},
    interruptedBy = {},
    defensivesUsed = {},
    killParticipation = {},
    assistParticipation = {},
}
local targetPriorities = {
    HEALER = 10,
    TANK = 5,
    DAMAGER = 7,
}
local bursterSpecializations = {
    -- Classes with burst potential (for focus targeting)
    [71] = true,   -- Arms Warrior
    [72] = true,   -- Fury Warrior
    [73] = true,   -- Protection Warrior
    [265] = true,  -- Affliction Warlock
    [266] = true,  -- Demonology Warlock
    [267] = true,  -- Destruction Warlock
    [254] = true,  -- Marksmanship Hunter
    [255] = true,  -- Survival Hunter
    [259] = true,  -- Assassination Rogue
    [260] = true,  -- Outlaw Rogue
    [261] = true,  -- Subtlety Rogue
    [62] = true,   -- Arcane Mage
    [63] = true,   -- Fire Mage
    [64] = true,   -- Frost Mage
    [250] = true,  -- Blood Death Knight
    [251] = true,  -- Frost Death Knight
    [252] = true,  -- Unholy Death Knight
    [577] = true,  -- Havoc Demon Hunter
    [1467] = true, -- Devastation Evoker
    [1468] = true, -- Preservation Evoker
    [1473] = true, -- Augmentation Evoker
}
local highSurvivalSpecializations = {
    -- Classes with high survivability (lower priority)
    [268] = true,  -- Brewmaster Monk
    [269] = true,  -- Windwalker Monk
    [270] = true,  -- Mistweaver Monk
    [66] = true,   -- Protection Paladin
    [104] = true,  -- Guardian Druid
    [581] = true,  -- Vengeance Demon Hunter
}

-- Initialize the PvP Manager
function PvPManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Create PvP frame
    self:CreatePvPFrame()
    
    -- Register events
    self:RegisterEvents()
    
    -- Update PvP state
    self:UpdatePvPState()
    
    API.PrintDebug("PvP Manager initialized")
    return true
end

-- Register settings
function PvPManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("PvPManager", {
        generalSettings = {
            enablePvPMode = {
                displayName = "Enable PvP Mode",
                description = "Automatically optimize rotations for PvP",
                type = "toggle",
                default = true
            },
            smartTargeting = {
                displayName = "Smart Targeting",
                description = "Automatically target high-priority enemies based on role and status",
                type = "toggle",
                default = true
            },
            prioritizeHealers = {
                displayName = "Prioritize Healers",
                description = "Target enemy healers with higher priority",
                type = "toggle",
                default = true
            },
            lowHealthPriority = {
                displayName = "Low Health Priority",
                description = "Prioritize targets with lower health",
                type = "toggle",
                default = true
            },
            adaptToEnemyComp = {
                displayName = "Adapt to Enemy Comp",
                description = "Adjust rotation based on enemy team composition",
                type = "toggle",
                default = true
            },
            quickSwapBindings = {
                displayName = "Quick Swap Bindings",
                description = "Enable quick target swap for arena123 bindings",
                type = "toggle",
                default = true
            }
        },
        arenaSettings = {
            enableArenaTracking = {
                displayName = "Enable Arena Tracking",
                description = "Track enemy cooldowns and DR in arena",
                type = "toggle",
                default = true
            },
            arenaTrinketTracking = {
                displayName = "Arena Trinket Tracking",
                description = "Track enemy PvP trinket usage",
                type = "toggle",
                default = true
            },
            focusHighestDps = {
                displayName = "Focus Highest DPS",
                description = "Automatically set focus on highest DPS enemy",
                type = "toggle",
                default = true
            },
            announceInterrupts = {
                displayName = "Announce Interrupts",
                description = "Announce successful interrupts to team",
                type = "toggle",
                default = false
            },
            announceCrowdControl = {
                displayName = "Announce CC",
                description = "Announce crowd control on enemies to team",
                type = "toggle",
                default = false
            },
            adaptiveHealing = {
                displayName = "Adaptive Healing",
                description = "Adjust healing priorities based on arena situation",
                type = "toggle",
                default = true
            }
        },
        bgSettings = {
            enableBGOptimization = {
                displayName = "Enable BG Optimization",
                description = "Optimize rotation for battlegrounds",
                type = "toggle",
                default = true
            },
            objectivePriority = {
                displayName = "Objective Priority",
                description = "Prioritize players near objectives",
                type = "toggle",
                default = true
            },
            bgCallouts = {
                displayName = "BG Callouts",
                description = "Provide automatic battleground callouts",
                type = "toggle",
                default = false
            },
            assistTeammates = {
                displayName = "Assist Teammates",
                description = "Automatically assist teammates who are under attack",
                type = "toggle",
                default = true
            },
            flagCarrierFocus = {
                displayName = "Flag Carrier Focus",
                description = "Automatically focus enemy flag carriers",
                type = "toggle",
                default = true
            }
        },
        drSettings = {
            enableDRTracking = {
                displayName = "Enable DR Tracking",
                description = "Track and display diminishing returns on CC",
                type = "toggle",
                default = true
            },
            drCategoryColors = {
                displayName = "DR Category Colors",
                description = "Use color coding for different DR categories",
                type = "toggle",
                default = true
            },
            drAudioWarning = {
                displayName = "DR Audio Warning",
                description = "Play sound when DR is about to reset",
                type = "toggle",
                default = true
            },
            smartCCBasedOnDR = {
                displayName = "Smart CC Based on DR",
                description = "Suggest CC based on current DR status",
                type = "toggle",
                default = true
            },
            showDRTimers = {
                displayName = "Show DR Timers",
                description = "Display DR timers on enemy nameplates",
                type = "toggle",
                default = true
            }
        },
        defensiveSettings = {
            defensiveAwareness = {
                displayName = "Defensive Awareness",
                description = "Automatically use defensive abilities when needed",
                type = "toggle",
                default = true
            },
            trinketSaver = {
                displayName = "Trinket Saver",
                description = "Save trinket for important CC",
                type = "toggle",
                default = true
            },
            importantCCs = {
                displayName = "Important CCs",
                description = "CCs that should trigger trinket usage",
                type = "multiselect",
                options = {"Stun", "Fear", "Polymorph", "Cyclone", "Hex"},
                default = {"Stun", "Fear"}
            },
            defensiveThreshold = {
                displayName = "Defensive Threshold",
                description = "Health percentage to use defensive cooldowns",
                type = "slider",
                min = 10,
                max = 60,
                step = 5,
                default = 40
            },
            burstDetection = {
                displayName = "Burst Detection",
                description = "Detect enemy burst and use appropriate defensives",
                type = "toggle",
                default = true
            }
        }
    })
}

-- Create PvP frame
function PvPManager:CreatePvPFrame()
    pvpFrame = CreateFrame("Frame", "WindrunnerRotationsPvPFrame")
    
    -- Set up OnUpdate handler
    pvpFrame:SetScript("OnUpdate", function(self, elapsed)
        PvPManager:OnUpdate(elapsed)
    end)
}

-- Register events
function PvPManager:RegisterEvents()
    -- Register for zone changes
    API.RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        PvPManager:UpdatePvPState()
    end)
    
    API.RegisterEvent("PLAYER_ENTERING_WORLD", function()
        PvPManager:UpdatePvPState()
    end)
    
    -- Register for arena events
    API.RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", function()
        PvPManager:OnArenaPrep()
    end)
    
    API.RegisterEvent("ARENA_OPPONENT_UPDATE", function(unit, updateReason)
        PvPManager:OnArenaOpponentUpdate(unit, updateReason)
    end)
    
    -- Register for battleground events
    API.RegisterEvent("UPDATE_BATTLEFIELD_STATUS", function(index)
        PvPManager:OnBattlefieldStatusUpdate(index)
    end)
    
    API.RegisterEvent("UPDATE_BATTLEFIELD_SCORE", function()
        PvPManager:OnBattlefieldScoreUpdate()
    end)
    
    -- Register for PvP trinket tracking
    API.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
        PvPManager:OnCombatLogEvent(CombatLogGetCurrentEventInfo())
    end)
    
    -- Register for unit events to track enemy status
    API.RegisterEvent("UNIT_AURA", function(unit)
        PvPManager:OnUnitAuraChanged(unit)
    end)
    
    API.RegisterEvent("UNIT_HEALTH", function(unit)
        PvPManager:OnUnitHealthChanged(unit)
    end)
    
    API.RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(unit, castGUID, spellID)
        PvPManager:OnUnitSpellcastSucceeded(unit, castGUID, spellID)
    end)
    
    -- Register for target/focus changes
    API.RegisterEvent("PLAYER_TARGET_CHANGED", function()
        PvPManager:OnTargetChanged()
    end)
    
    API.RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        PvPManager:OnFocusChanged()
    end)
}

-- OnUpdate handler
function PvPManager:OnUpdate(elapsed)
    -- Skip if disabled
    if not isEnabled then
        return
    end
    
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- Update time tracking
    lastUpdate = lastUpdate + elapsed
    
    -- Only update at the specified frequency
    if lastUpdate < updateFrequency then
        return
    end
    
    -- Reset update timer
    lastUpdate = 0
    
    -- Update arena enemies
    if inArena then
        self:UpdateArenaEnemies()
    end
    
    -- Update battleground data
    if inBattleground and GetTime() - lastBattlegroundUpdate > BATTLEGROUND_UPDATE_FREQ then
        self:UpdateBattlegroundData()
        lastBattlegroundUpdate = GetTime()
    end
    
    -- Update DR tracking
    self:UpdateDRTracking()
    
    -- Update target priorities
    self:UpdateTargetPriorities()
}

-- Update PvP state
function PvPManager:UpdatePvPState()
    -- Check if we're in arena
    local _, instanceType = IsInInstance()
    inArena = instanceType == "arena"
    inBattleground = instanceType == "pvp"
    inPvP = inArena or inBattleground or IsWarModeDesired()
    
    -- Debug output
    if inArena then
        API.PrintDebug("Entered arena")
        self:ResetArenaData()
        
        -- Determine arena type
        local numOpps = GetNumArenaOpponentSpecs()
        if numOpps == 2 then
            arenaType = "2v2"
        elseif numOpps == 3 then
            arenaType = "3v3"
        elseif numOpps == 5 then
            arenaType = "5v5"
        else
            arenaType = "Solo Shuffle"
        end
        
        -- Check if rated
        isRatedArena = IsRatedBattleground()
        
        API.PrintDebug("Arena type: " .. arenaType .. (isRatedArena and " (Rated)" or " (Skirmish)"))
    elseif inBattleground then
        API.PrintDebug("Entered battleground")
        
        -- Check if rated
        isRatedBG = IsRatedBattleground()
        
        -- Update battleground data
        self:UpdateBattlegroundData()
    elseif IsWarModeDesired() then
        API.PrintDebug("War Mode enabled")
    else
        API.PrintDebug("Not in PvP")
    end
    
    -- Initialize enemy team data
    self:InitializeEnemyTeam()
}

-- Reset arena data
function PvPManager:ResetArenaData()
    -- Clear arena enemies
    arenaEnemies = {}
    arenaAllies = {}
    enemyTeam = {}
    friendlyTeam = {}
    enemyHealer = nil
    enemyTank = nil
    enemyDPS = {}
    
    -- Reset DR tracking
    targetDR = {}
    enemyDR = {}
    
    -- Reset PvP combat metrics
    pvpCombatMetrics = {
        damageDone = {},
        healingDone = {},
        damageTaken = {},
        healingTaken = {},
        ccApplied = {},
        ccTaken = {},
        interruptsCast = {},
        interruptedBy = {},
        defensivesUsed = {},
        killParticipation = {},
        assistParticipation = {},
    }
}

-- Initialize enemy team
function PvPManager:InitializeEnemyTeam()
    -- Skip if not in arena
    if not inArena then
        return
    end
    
    -- Get enemy specs
    local numOpps = GetNumArenaOpponentSpecs()
    
    for i = 1, numOpps do
        -- Get spec info
        local specID = GetArenaOpponentSpec(i)
        if specID and specID > 0 then
            local id, name, description, icon, background, role = GetSpecializationInfoByID(specID)
            
            if id then
                -- Add to arena enemies array
                arenaEnemies[i] = {
                    specID = id,
                    name = name,
                    icon = icon,
                    role = role,
                    index = i,
                    unit = "arena" .. i,
                    health = 100,
                    isPriority = role == "HEALER",
                    isBurster = bursterSpecializations[id] or false,
                    hasHighSurvival = highSurvivalSpecializations[id] or false,
                    class = self:GetClassFromSpecID(id),
                    drInfo = {},
                    cooldowns = {},
                    isHealer = role == "HEALER",
                    isTank = role == "TANK",
                    trinketUsed = false,
                    trinketCooldown = 0,
                    trinketTime = 0,
                    defensivesUsed = {},
                    offensivesUsed = {},
                    ccHistory = {}
                }
                
                -- Populate enemy team structure
                enemyTeam[i] = arenaEnemies[i]
                
                -- Track healer
                if role == "HEALER" then
                    enemyHealer = arenaEnemies[i]
                elseif role == "TANK" then
                    enemyTank = arenaEnemies[i]
                else
                    table.insert(enemyDPS, arenaEnemies[i])
                end
                
                -- Set initial cooldowns
                self:InitializeEnemyCooldowns(arenaEnemies[i])
            end
        end
    end
    
    -- Initialize friendly team
    self:InitializeFriendlyTeam()
    
    -- Debug output for enemy team
    local teamComp = ""
    for i, enemy in ipairs(enemyTeam) do
        if i > 1 then teamComp = teamComp .. ", " end
        teamComp = teamComp .. (enemy.class or "Unknown") .. " (" .. (enemy.role or "Unknown") .. ")"
    end
    API.PrintDebug("Enemy comp: " .. teamComp)
end

-- Initialize friendly team
function PvPManager:InitializeFriendlyTeam()
    -- Clear friendly team
    friendlyTeam = {}
    allyHealer = nil
    
    -- Add player
    local playerSpecID = GetSpecializationInfo(GetSpecialization())
    local _, _, _, _, _, playerRole = GetSpecializationInfoByID(playerSpecID)
    local _, playerClass = UnitClass("player")
    
    friendlyTeam[1] = {
        specID = playerSpecID,
        role = playerRole,
        class = playerClass,
        unit = "player",
        name = UnitName("player"),
        health = 100,
        isHealer = playerRole == "HEALER",
        isTank = playerRole == "TANK"
    }
    
    if playerRole == "HEALER" then
        allyHealer = friendlyTeam[1]
    end
    
    -- Add party members
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        if UnitExists(unit) then
            -- Get role and class
            local role = UnitGroupRolesAssigned(unit)
            local _, class = UnitClass(unit)
            
            -- Add to friendly team
            friendlyTeam[i+1] = {
                unit = unit,
                role = role,
                class = class,
                name = UnitName(unit),
                health = UnitHealth(unit) / UnitHealthMax(unit) * 100,
                isHealer = role == "HEALER",
                isTank = role == "TANK"
            }
            
            -- Track healer
            if role == "HEALER" and not allyHealer then
                allyHealer = friendlyTeam[i+1]
            end
        end
    end
}

-- Initialize enemy cooldowns
function PvPManager:InitializeEnemyCooldowns(enemy)
    -- Set up cooldown tracking based on class and spec
    if not enemy or not enemy.class then 
        return 
    end
    
    -- Common PvP trinket
    enemy.cooldowns["PvPTrinket"] = {
        name = "PvP Trinket",
        duration = 120,
        lastUsed = 0,
        onCooldown = false,
        remaining = 0,
        icon = 136092  -- Default trinket icon
    }
    
    -- Add class-specific cooldowns
    if enemy.class == "PALADIN" then
        enemy.cooldowns["DivineProt"] = {
            name = "Divine Protection",
            duration = 60,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
        enemy.cooldowns["DivineShield"] = {
            name = "Divine Shield",
            duration = 300,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
    elseif enemy.class == "WARRIOR" then
        enemy.cooldowns["DieByTheSword"] = {
            name = "Die By the Sword",
            duration = 120,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
        enemy.cooldowns["Avatar"] = {
            name = "Avatar",
            duration = 90,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
    elseif enemy.class == "DRUID" then
        enemy.cooldowns["Barkskin"] = {
            name = "Barkskin",
            duration = 60,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
        enemy.cooldowns["SurvivalInstincts"] = {
            name = "Survival Instincts",
            duration = 180,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
    elseif enemy.class == "PRIEST" then
        enemy.cooldowns["Fade"] = {
            name = "Fade",
            duration = 30,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
        enemy.cooldowns["PainSuppression"] = {
            name = "Pain Suppression",
            duration = 180,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
    elseif enemy.class == "MAGE" then
        enemy.cooldowns["IceBlock"] = {
            name = "Ice Block",
            duration = 240,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
        enemy.cooldowns["Combustion"] = {
            name = "Combustion",
            duration = 120,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
    elseif enemy.class == "WARLOCK" then
        enemy.cooldowns["UnendingResolve"] = {
            name = "Unending Resolve",
            duration = 180,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
        enemy.cooldowns["SoulRot"] = {
            name = "Soul Rot",
            duration = 120,
            lastUsed = 0,
            onCooldown = false,
            remaining = 0
        }
    end
    
    -- Add spec-specific major cooldowns
    if enemy.specID then
        if enemy.specID == 65 then -- Holy Paladin
            enemy.cooldowns["AuraOfMercy"] = {
                name = "Aura of Mercy",
                duration = 180,
                lastUsed = 0,
                onCooldown = false,
                remaining = 0
            }
        elseif enemy.specID == 270 then -- Mistweaver Monk
            enemy.cooldowns["Revival"] = {
                name = "Revival",
                duration = 180,
                lastUsed = 0,
                onCooldown = false,
                remaining = 0
            }
        elseif enemy.specID == 256 then -- Discipline Priest
            enemy.cooldowns["Rapture"] = {
                name = "Rapture",
                duration = 90,
                lastUsed = 0,
                onCooldown = false,
                remaining = 0
            }
        end
    end
}

-- Get class from spec ID
function PvPManager:GetClassFromSpecID(specID)
    if not specID then return nil end
    
    -- This is a mapping of spec IDs to classes
    local classSpecs = {
        -- Death Knight
        [250] = "DEATHKNIGHT", -- Blood
        [251] = "DEATHKNIGHT", -- Frost
        [252] = "DEATHKNIGHT", -- Unholy
        
        -- Demon Hunter
        [577] = "DEMONHUNTER", -- Havoc
        [581] = "DEMONHUNTER", -- Vengeance
        
        -- Druid
        [102] = "DRUID", -- Balance
        [103] = "DRUID", -- Feral
        [104] = "DRUID", -- Guardian
        [105] = "DRUID", -- Restoration
        
        -- Evoker
        [1467] = "EVOKER", -- Devastation
        [1468] = "EVOKER", -- Preservation
        [1473] = "EVOKER", -- Augmentation
        
        -- Hunter
        [253] = "HUNTER", -- Beast Mastery
        [254] = "HUNTER", -- Marksmanship
        [255] = "HUNTER", -- Survival
        
        -- Mage
        [62] = "MAGE", -- Arcane
        [63] = "MAGE", -- Fire
        [64] = "MAGE", -- Frost
        
        -- Monk
        [268] = "MONK", -- Brewmaster
        [269] = "MONK", -- Windwalker
        [270] = "MONK", -- Mistweaver
        
        -- Paladin
        [65] = "PALADIN", -- Holy
        [66] = "PALADIN", -- Protection
        [70] = "PALADIN", -- Retribution
        
        -- Priest
        [256] = "PRIEST", -- Discipline
        [257] = "PRIEST", -- Holy
        [258] = "PRIEST", -- Shadow
        
        -- Rogue
        [259] = "ROGUE", -- Assassination
        [260] = "ROGUE", -- Outlaw
        [261] = "ROGUE", -- Subtlety
        
        -- Shaman
        [262] = "SHAMAN", -- Elemental
        [263] = "SHAMAN", -- Enhancement
        [264] = "SHAMAN", -- Restoration
        
        -- Warlock
        [265] = "WARLOCK", -- Affliction
        [266] = "WARLOCK", -- Demonology
        [267] = "WARLOCK", -- Destruction
        
        -- Warrior
        [71] = "WARRIOR", -- Arms
        [72] = "WARRIOR", -- Fury
        [73] = "WARRIOR", -- Protection
    }
    
    return classSpecs[specID]
end

-- On arena prep
function PvPManager:OnArenaPrep()
    -- Reset arena data
    self:ResetArenaData()
    
    -- Initialize enemy team
    self:InitializeEnemyTeam()
}

-- On arena opponent update
function PvPManager:OnArenaOpponentUpdate(unit, updateReason)
    -- Skip if not in arena
    if not inArena then
        return
    end
    
    -- Get opponent index
    local index = tonumber(string.match(unit, "arena(%d)"))
    if not index or not arenaEnemies[index] then
        return
    end
    
    -- Get unit information
    if UnitExists(unit) then
        arenaEnemies[index].name = UnitName(unit)
        arenaEnemies[index].health = UnitHealth(unit) / UnitHealthMax(unit) * 100
        
        -- Update class and spec if available
        local _, class = UnitClass(unit)
        if class then
            arenaEnemies[index].class = class
        end
    end
}

-- Update arena enemies
function PvPManager:UpdateArenaEnemies()
    -- Skip if not in arena
    if not inArena then
        return
    end
    
    -- Update arena enemy data
    for i, enemy in ipairs(arenaEnemies) do
        local unit = "arena" .. i
        if UnitExists(unit) then
            -- Update health
            local healthMax = UnitHealthMax(unit)
            if healthMax > 0 then
                enemy.health = UnitHealth(unit) / healthMax * 100
            else
                enemy.health = 0
            end
            
            -- Update cooldowns
            self:UpdateEnemyCooldowns(enemy)
            
            -- Update DR info
            self:UpdateEnemyDRInfo(enemy)
        end
    end
}

-- Update enemy cooldowns
function PvPManager:UpdateEnemyCooldowns(enemy)
    local now = GetTime()
    
    -- Update all cooldown timers
    for cooldownName, cooldown in pairs(enemy.cooldowns) do
        if cooldown.onCooldown then
            local elapsed = now - cooldown.lastUsed
            local remaining = cooldown.duration - elapsed
            
            -- Update remaining time
            cooldown.remaining = math.max(0, remaining)
            
            -- Reset if expired
            if cooldown.remaining <= 0 then
                cooldown.onCooldown = false
                cooldown.remaining = 0
                
                -- Debug output
                API.PrintDebug(enemy.name .. "'s " .. cooldown.name .. " is now available")
            end
        end
    end
    
    -- Special case: PvP trinket
    if enemy.trinketUsed then
        local elapsed = now - enemy.trinketTime
        local remaining = 120 - elapsed -- 2 minute cooldown
        
        enemy.trinketCooldown = math.max(0, remaining)
        
        if enemy.trinketCooldown <= 0 then
            enemy.trinketUsed = false
            enemy.trinketCooldown = 0
            
            -- Debug output
            API.PrintDebug(enemy.name .. "'s PvP trinket is now available")
        end
    end
}

-- Update enemy DR info
function PvPManager:UpdateEnemyDRInfo(enemy)
    local now = GetTime()
    
    -- Update all DR timers
    for category, dr in pairs(enemy.drInfo) do
        if dr.active then
            local elapsed = now - dr.lastApplied
            local remaining = diminishingReturns[category].duration - elapsed
            
            -- Update remaining time
            dr.remaining = math.max(0, remaining)
            
            -- Reset if expired
            if dr.remaining <= 0 then
                dr.active = false
                dr.remaining = 0
                dr.applications = 0
                
                -- Debug output
                API.PrintDebug(enemy.name .. "'s " .. category .. " DR has reset")
            end
        end
    end
}

-- On battlefield status update
function PvPManager:OnBattlefieldStatusUpdate(index)
    -- Update battleground state
    local status = GetBattlefieldStatus(index)
    
    if status == "active" then
        -- We're in an active battleground
        local instanceID = select(8, GetInstanceInfo())
        if instanceID then
            -- Identify battleground type
            self:IdentifyBattlegroundType(instanceID)
        end
    end
}

-- On battlefield score update
function PvPManager:OnBattlefieldScoreUpdate()
    -- Update battleground score data
    if inBattleground then
        self:UpdateBattlegroundData()
    end
}

-- Update battleground data
function PvPManager:UpdateBattlegroundData()
    -- This would collect battleground-specific data
    local _, instanceType, _, _, _, teamSize = GetInstanceInfo()
    
    if instanceType ~= "pvp" then
        return
    end
    
    -- Update last battleground update time
    lastBattlegroundUpdate = GetTime()
}

-- Identify battleground type
function PvPManager:IdentifyBattlegroundType(instanceID)
    -- Map instance IDs to battleground types
    local bgTypes = {
        [30] = "Alterac Valley",
        [529] = "Arathi Basin",
        [489] = "Warsong Gulch",
        [566] = "Eye of the Storm",
        [607] = "Strand of the Ancients",
        [628] = "Isle of Conquest",
        [726] = "Twin Peaks",
        [761] = "Battle for Gilneas",
        [968] = "Rated Battleground",
        [998] = "Temple of Kotmogu",
        [1105] = "Deepwind Gorge",
        [1681] = "Ashran",
        [2106] = "Warsong Gulch",
        [2107] = "Arathi Basin",
        [2118] = "Battle for Gilneas",
        [3358] = "Seething Shore",
        [5031] = "Wartorn Ancient Keeper"
    }
    
    local bgType = bgTypes[instanceID] or "Unknown Battleground"
    API.PrintDebug("Entered battleground: " .. bgType)
}

-- On combat log event
function PvPManager:OnCombatLogEvent(timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
                                   destGUID, destName, destFlags, destRaidFlags, ...)
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- Process PvP trinket usage
    if eventType == "SPELL_CAST_SUCCESS" then
        local spellID, spellName = ...
        
        -- Check if this is a PvP trinket
        if pvpTrinketIDs[spellID] then
            self:OnPvPTrinketUsed(sourceGUID, sourceName)
        end
        
        -- Process interrupt events
        if self:IsInterruptSpell(spellID) and destGUID then
            self:OnInterruptCast(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
        end
        
        -- Process cooldown usage
        self:ProcessCooldownUsage(sourceGUID, sourceName, spellID, spellName)
    end
    
    -- Process CC application for DR tracking
    if eventType == "SPELL_AURA_APPLIED" then
        local spellID, spellName, spellSchool, auraType = ...
        
        -- Only track debuffs
        if auraType == "DEBUFF" then
            -- Get DR category for this spell
            local category = drCategories[spellID]
            
            if category then
                self:OnCCApplied(sourceGUID, sourceName, destGUID, destName, spellID, spellName, category)
            end
        end
    end
    
    -- Process damage/healing for PvP metrics
    if eventType == "SPELL_DAMAGE" or eventType == "SPELL_PERIODIC_DAMAGE" then
        local spellID, spellName, spellSchool, amount = ...
        
        -- Record damage
        if sourceGUID == UnitGUID("player") then
            -- Damage done by player
            pvpCombatMetrics.damageDone[destGUID] = (pvpCombatMetrics.damageDone[destGUID] or 0) + (amount or 0)
        elseif destGUID == UnitGUID("player") then
            -- Damage taken by player
            pvpCombatMetrics.damageTaken[sourceGUID] = (pvpCombatMetrics.damageTaken[sourceGUID] or 0) + (amount or 0)
        end
    elseif eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL" then
        local spellID, spellName, spellSchool, amount, overhealing = ...
        local effectiveHealing = (amount or 0) - (overhealing or 0)
        
        -- Record healing
        if sourceGUID == UnitGUID("player") then
            -- Healing done by player
            pvpCombatMetrics.healingDone[destGUID] = (pvpCombatMetrics.healingDone[destGUID] or 0) + effectiveHealing
        elseif destGUID == UnitGUID("player") then
            -- Healing received by player
            pvpCombatMetrics.healingTaken[sourceGUID] = (pvpCombatMetrics.healingTaken[sourceGUID] or 0) + effectiveHealing
        end
    end
}

-- On PvP trinket used
function PvPManager:OnPvPTrinketUsed(unitGUID, unitName)
    -- Skip if trinket tracking is disabled
    local settings = ConfigRegistry:GetSettings("PvPManager")
    if not settings.arenaSettings.arenaTrinketTracking then
        return
    end
    
    -- Find the enemy who used the trinket
    for _, enemy in ipairs(arenaEnemies) do
        -- Check if this is the unit
        if UnitGUID(enemy.unit) == unitGUID then
            -- Record trinket usage
            enemy.trinketUsed = true
            enemy.trinketTime = GetTime()
            
            -- Update cooldown info
            if enemy.cooldowns["PvPTrinket"] then
                enemy.cooldowns["PvPTrinket"].onCooldown = true
                enemy.cooldowns["PvPTrinket"].lastUsed = GetTime()
                enemy.cooldowns["PvPTrinket"].remaining = 120 -- 2 minute cooldown
            end
            
            -- Announce trinket usage
            API.PrintMessage(enemy.name .. " used PvP trinket!")
            
            -- Debug output
            API.PrintDebug(enemy.name .. " (" .. enemy.class .. ") used PvP trinket, on cooldown for 2 minutes")
            break
        end
    end
}

-- On CC applied
function PvPManager:OnCCApplied(sourceGUID, sourceName, destGUID, destName, spellID, spellName, category)
    -- Skip if DR tracking is disabled
    local settings = ConfigRegistry:GetSettings("PvPManager")
    if not settings.drSettings.enableDRTracking then
        return
    end
    
    -- Find the enemy who was CC'd
    local targetEnemy = nil
    for _, enemy in ipairs(arenaEnemies) do
        if UnitGUID(enemy.unit) == destGUID then
            targetEnemy = enemy
            break
        end
    end
    
    -- If not an arena enemy, check if it's the current target
    if not targetEnemy and UnitGUID("target") == destGUID then
        -- Create DR info for this target
        if not targetDR[category] then
            targetDR[category] = {
                applications = 0,
                lastApplied = 0,
                active = false,
                remaining = 0,
                diminished = false
            }
        end
        
        -- Update DR info
        local dr = targetDR[category]
        dr.applications = dr.applications + 1
        dr.lastApplied = GetTime()
        dr.active = true
        dr.remaining = diminishingReturns[category].duration
        
        -- Calculate diminished duration based on number of applications
        local applications = math.min(dr.applications, #diminishingReturns[category].multipliers)
        local multiplier = diminishingReturns[category].multipliers[applications]
        
        -- Debug output
        API.PrintDebug(destName .. " hit with " .. spellName .. " (" .. category .. " DR), multiplier: " .. multiplier)
        
        return
    end
    
    -- Update enemy DR info
    if targetEnemy then
        -- Create DR info for this category if it doesn't exist
        if not targetEnemy.drInfo[category] then
            targetEnemy.drInfo[category] = {
                applications = 0,
                lastApplied = 0,
                active = false,
                remaining = 0,
                diminished = false
            }
        end
        
        -- Update DR info
        local dr = targetEnemy.drInfo[category]
        dr.applications = dr.applications + 1
        dr.lastApplied = GetTime()
        dr.active = true
        dr.remaining = diminishingReturns[category].duration
        
        -- Calculate diminished duration based on number of applications
        local applications = math.min(dr.applications, #diminishingReturns[category].multipliers)
        local multiplier = diminishingReturns[category].multipliers[applications]
        dr.diminished = multiplier < 1
        
        -- Record CC application
        table.insert(targetEnemy.ccHistory, {
            spellID = spellID,
            spellName = spellName,
            category = category,
            timestamp = GetTime(),
            sourceGUID = sourceGUID,
            sourceName = sourceName,
            multiplier = multiplier
        })
        
        -- Debug output
        API.PrintDebug(targetEnemy.name .. " hit with " .. spellName .. " (" .. category .. " DR), multiplier: " .. multiplier)
        
        -- Record for player metrics
        if sourceGUID == UnitGUID("player") then
            pvpCombatMetrics.ccApplied[destGUID] = (pvpCombatMetrics.ccApplied[destGUID] or 0) + 1
        elseif destGUID == UnitGUID("player") then
            pvpCombatMetrics.ccTaken[sourceGUID] = (pvpCombatMetrics.ccTaken[sourceGUID] or 0) + 1
        end
        
        -- Announce CC application if enabled
        if settings.arenaSettings.announceCrowdControl and sourceGUID == UnitGUID("player") then
            local message = spellName .. " on " .. targetEnemy.name
            if multiplier < 1 then
                message = message .. " (DR: " .. (multiplier * 100) .. "%)"
            end
            
            if IsInGroup() then
                SendChatMessage(message, "PARTY")
            end
        end
    end
}

-- On interrupt cast
function PvPManager:OnInterruptCast(sourceGUID, sourceName, destGUID, destName, spellID, spellName)
    -- Skip if interrupt tracking is disabled
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    -- Record interrupts for metrics
    if sourceGUID == UnitGUID("player") then
        pvpCombatMetrics.interruptsCast[destGUID] = (pvpCombatMetrics.interruptsCast[destGUID] or 0) + 1
        
        -- Announce interrupt if enabled
        if settings.arenaSettings.announceInterrupts then
            local message = "Interrupted " .. destName .. " with " .. spellName
            
            if IsInGroup() then
                SendChatMessage(message, "PARTY")
            end
        end
    elseif destGUID == UnitGUID("player") then
        pvpCombatMetrics.interruptedBy[sourceGUID] = (pvpCombatMetrics.interruptedBy[sourceGUID] or 0) + 1
    end
}

-- Process cooldown usage
function PvPManager:ProcessCooldownUsage(sourceGUID, sourceName, spellID, spellName)
    -- Find the enemy who used the cooldown
    for _, enemy in ipairs(arenaEnemies) do
        -- Check if this is the unit
        if UnitGUID(enemy.unit) == sourceGUID then
            -- Check various cooldowns based on class
            self:CheckClassCooldowns(enemy, spellID, spellName)
            break
        end
    end
}

-- Check class cooldowns
function PvPManager:CheckClassCooldowns(enemy, spellID, spellName)
    -- Check various cooldowns
    local cooldownMap = {
        -- Paladin
        [642] = "DivineShield", -- Divine Shield
        [498] = "DivineProt",   -- Divine Protection
        
        -- Warrior
        [118038] = "DieByTheSword", -- Die By the Sword
        [107574] = "Avatar",        -- Avatar
        
        -- Druid
        [22812] = "Barkskin",          -- Barkskin
        [61336] = "SurvivalInstincts", -- Survival Instincts
        
        -- Priest
        [19236] = "Fade",             -- Fade
        [33206] = "PainSuppression",  -- Pain Suppression
        
        -- Mage
        [45438] = "IceBlock",   -- Ice Block
        [190319] = "Combustion", -- Combustion
        
        -- Warlock
        [104773] = "UnendingResolve", -- Unending Resolve
        [325640] = "SoulRot",         -- Soul Rot
        
        -- Death Knight
        [48792] = "IceboundFortitude", -- Icebound Fortitude
        
        -- Demon Hunter
        [198589] = "Blur", -- Blur
        
        -- Hunter
        [186265] = "AspectOfTheTurtle", -- Aspect of the Turtle
        
        -- Monk
        [122470] = "TouchOfKarma", -- Touch of Karma
        
        -- Rogue
        [1856] = "Vanish" -- Vanish
    }
    
    -- Check if this spell is a tracked cooldown
    local cooldownKey = cooldownMap[spellID]
    if cooldownKey and enemy.cooldowns[cooldownKey] then
        -- Update cooldown info
        enemy.cooldowns[cooldownKey].onCooldown = true
        enemy.cooldowns[cooldownKey].lastUsed = GetTime()
        enemy.cooldowns[cooldownKey].remaining = enemy.cooldowns[cooldownKey].duration
        
        -- Debug output
        API.PrintDebug(enemy.name .. " used " .. enemy.cooldowns[cooldownKey].name .. ", on cooldown for " .. 
                      enemy.cooldowns[cooldownKey].duration .. " seconds")
    end
}

-- On unit aura changed
function PvPManager:OnUnitAuraChanged(unit)
    -- Skip if not an arena unit
    if not unit:match("arena%d") then
        return
    end
    
    -- Find corresponding arena enemy
    local index = tonumber(string.match(unit, "arena(%d)"))
    if not index or not arenaEnemies[index] then
        return
    end
    
    -- Check for important buffs/debuffs
    self:CheckImportantAuras(arenaEnemies[index])
}

-- Check important auras
function PvPManager:CheckImportantAuras(enemy)
    -- This would check for important buffs and debuffs on an enemy
    -- Such as immunities, defensives, CC, etc.
}

-- On unit health changed
function PvPManager:OnUnitHealthChanged(unit)
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- If this is an arena unit, update health
    if unit:match("arena%d") then
        local index = tonumber(string.match(unit, "arena(%d)"))
        if index and arenaEnemies[index] then
            local healthMax = UnitHealthMax(unit)
            if healthMax > 0 then
                arenaEnemies[index].health = UnitHealth(unit) / healthMax * 100
            else
                arenaEnemies[index].health = 0
            end
        end
    elseif unit:match("party%d") or unit == "player" then
        -- Update friendly health
        local index = unit == "player" and 1 or tonumber(string.match(unit, "party(%d)")) + 1
        if index and friendlyTeam[index] then
            local healthMax = UnitHealthMax(unit)
            if healthMax > 0 then
                friendlyTeam[index].health = UnitHealth(unit) / healthMax * 100
            else
                friendlyTeam[index].health = 0
            end
        end
    end
}

-- On unit spellcast succeeded
function PvPManager:OnUnitSpellcastSucceeded(unit, castGUID, spellID)
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- If this is an arena unit, check cooldowns
    if unit:match("arena%d") then
        local index = tonumber(string.match(unit, "arena(%d)"))
        if index and arenaEnemies[index] then
            -- Get spell name for debug
            local spellName = GetSpellInfo(spellID)
            
            -- Process cooldown usage
            self:ProcessCooldownUsage(UnitGUID(unit), UnitName(unit), spellID, spellName)
        end
    end
}

-- On target changed
function PvPManager:OnTargetChanged()
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- If target is an arena enemy, update target index
    if UnitExists("target") then
        local targetGUID = UnitGUID("target")
        
        for i, enemy in ipairs(arenaEnemies) do
            if UnitGUID(enemy.unit) == targetGUID then
                targetEnemyIndex = i
                
                -- Debug output
                API.PrintDebug("Targeting " .. enemy.name .. " (" .. enemy.class .. ", " .. enemy.role .. ")")
                break
            end
        end
    else
        targetEnemyIndex = nil
    end
}

-- On focus changed
function PvPManager:OnFocusChanged()
    -- Skip if not in PvP
    if not inPvP then
        return
    end
    
    -- If focus is an arena enemy, update focus index
    if UnitExists("focus") then
        local focusGUID = UnitGUID("focus")
        
        for i, enemy in ipairs(arenaEnemies) do
            if UnitGUID(enemy.unit) == focusGUID then
                focusEnemyIndex = i
                
                -- Debug output
                API.PrintDebug("Focus set to " .. enemy.name .. " (" .. enemy.class .. ", " .. enemy.role .. ")")
                break
            end
        end
    else
        focusEnemyIndex = nil
    end
}

-- Update DR tracking
function PvPManager:UpdateDRTracking()
    -- Skip if DR tracking is disabled
    local settings = ConfigRegistry:GetSettings("PvPManager")
    if not settings.drSettings.enableDRTracking then
        return
    end
    
    local now = GetTime()
    
    -- Update DR for current target
    for category, dr in pairs(targetDR) do
        if dr.active then
            local elapsed = now - dr.lastApplied
            local remaining = diminishingReturns[category].duration - elapsed
            
            -- Update remaining time
            dr.remaining = math.max(0, remaining)
            
            -- Reset if expired
            if dr.remaining <= 0 then
                dr.active = false
                dr.remaining = 0
                dr.applications = 0
                
                -- Debug output if target exists
                if UnitExists("target") then
                    API.PrintDebug(UnitName("target") .. "'s " .. category .. " DR has reset")
                end
            end
        end
    end
    
    -- Update global DR tracking
    for category, dr in pairs(globalDR) do
        if dr.active then
            local elapsed = now - dr.lastApplied
            local remaining = diminishingReturns[category].duration - elapsed
            
            -- Update remaining time
            dr.remaining = math.max(0, remaining)
            
            -- Reset if expired
            if dr.remaining <= 0 then
                dr.active = false
                dr.remaining = 0
                dr.applications = 0
            end
        end
    end
}

-- Update target priorities
function PvPManager:UpdateTargetPriorities()
    -- Skip if not in PvP or smart targeting is disabled
    local settings = ConfigRegistry:GetSettings("PvPManager")
    if not inPvP or not settings.generalSettings.smartTargeting then
        return
    end
    
    -- Skip if all enemies are processed
    if #arenaEnemies == 0 then
        return
    end
    
    -- Calculate priority for each enemy
    for _, enemy in ipairs(arenaEnemies) do
        -- Start with base priority by role
        enemy.priority = targetPriorities[enemy.role] or 7
        
        -- Adjust for healer priority
        if enemy.isHealer and settings.generalSettings.prioritizeHealers then
            enemy.priority = enemy.priority + 3
        end
        
        -- Adjust for low health priority
        if settings.generalSettings.lowHealthPriority and enemy.health < 30 then
            enemy.priority = enemy.priority + 2
        end
        
        -- Adjust for burst potential
        if enemy.isBurster and enemy.health < 50 then
            enemy.priority = enemy.priority + 1
        end
        
        -- Adjust for high survivability
        if enemy.hasHighSurvival then
            enemy.priority = enemy.priority - 1
        end
        
        -- Adjust for trinket status
        if enemy.trinketUsed then
            enemy.priority = enemy.priority + 1
        end
    end
    
    -- Find highest priority target
    local highestPriority = 0
    local highestPriorityEnemy = nil
    
    for _, enemy in ipairs(arenaEnemies) do
        if enemy.priority > highestPriority then
            highestPriority = enemy.priority
            highestPriorityEnemy = enemy
        end
    end
    
    -- Debug output for highest priority target
    if highestPriorityEnemy then
        API.PrintDebug("Highest priority target: " .. highestPriorityEnemy.name .. 
                      " (Priority: " .. highestPriorityEnemy.priority .. ", Health: " .. 
                      math.floor(highestPriorityEnemy.health) .. "%)")
    end
}

-- Is spell interruptible
function PvPManager:IsInterruptSpell(spellID)
    -- Common interrupt abilities
    local interruptSpells = {
        2139,   -- Counterspell (Mage)
        1766,   -- Kick (Rogue)
        6552,   -- Pummel (Warrior)
        47528,  -- Mind Freeze (Death Knight)
        96231,  -- Rebuke (Paladin)
        57994,  -- Wind Shear (Shaman)
        183752, -- Disrupt (Demon Hunter)
        19647,  -- Spell Lock (Warlock)
        147362, -- Counter Shot (Hunter)
        116705, -- Spear Hand Strike (Monk)
        78675,  -- Solar Beam (Druid)
        15487   -- Silence (Priest)
    }
    
    for _, id in ipairs(interruptSpells) do
        if id == spellID then
            return true
        end
    end
    
    return false
}

-- Should use trinket
function PvPManager:ShouldUseTrinket(ccType)
    -- Skip if not in PvP
    if not inPvP then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    -- Check if trinket saver is enabled
    if not settings.defensiveSettings.trinketSaver then
        return false
    end
    
    -- Check if this CC type is important
    local importantCCs = settings.defensiveSettings.importantCCs or {"Stun", "Fear"}
    
    for _, importantCC in ipairs(importantCCs) do
        if ccType:lower() == importantCC:lower() then
            return true
        end
    end
    
    return false
}

-- Should use defensive
function PvPManager:ShouldUseDefensive(healthPercent, burstDetected)
    -- Skip if not in PvP
    if not inPvP then
        return false
    end
    
    -- Get settings
    local settings = ConfigRegistry:GetSettings("PvPManager")
    
    -- Check if defensive awareness is enabled
    if not settings.defensiveSettings.defensiveAwareness then
        return false
    end
    
    -- Get defensive threshold
    local threshold = settings.defensiveSettings.defensiveThreshold or 40
    
    -- Check health threshold
    if healthPercent <= threshold then
        return true
    end
    
    -- Check burst detection
    if burstDetected and settings.defensiveSettings.burstDetection then
        return true
    end
    
    return false
}

-- Get arena enemy by unit ID
function PvPManager:GetArenaEnemyByUnit(unit)
    -- Extract index from unit ID
    local index = tonumber(string.match(unit, "arena(%d)"))
    if index and arenaEnemies[index] then
        return arenaEnemies[index]
    end
    
    return nil
end

-- Get arena enemy by GUID
function PvPManager:GetArenaEnemyByGUID(guid)
    for _, enemy in ipairs(arenaEnemies) do
        if UnitGUID(enemy.unit) == guid then
            return enemy
        end
    end
    
    return nil
end

-- Get target DR info
function PvPManager:GetTargetDRInfo(category)
    -- Skip if not in PvP
    if not inPvP then
        return nil
    end
    
    -- Check if we have DR info for this category
    if targetDR[category] then
        return targetDR[category]
    end
    
    return nil
end

-- Get enemy DR info
function PvPManager:GetEnemyDRInfo(unitOrIndex, category)
    -- Skip if not in PvP
    if not inPvP then
        return nil
    end
    
    -- Convert unit to index if needed
    local index = unitOrIndex
    if type(unitOrIndex) == "string" then
        index = tonumber(string.match(unitOrIndex, "arena(%d)"))
    end
    
    -- Check if we have an enemy for this index
    if index and arenaEnemies[index] and arenaEnemies[index].drInfo[category] then
        return arenaEnemies[index].drInfo[category]
    end
    
    return nil
}

-- Get enemy cooldown
function PvPManager:GetEnemyCooldown(unitOrIndex, cooldownName)
    -- Skip if not in PvP
    if not inPvP then
        return nil
    end
    
    -- Convert unit to index if needed
    local index = unitOrIndex
    if type(unitOrIndex) == "string" then
        index = tonumber(string.match(unitOrIndex, "arena(%d)"))
    end
    
    -- Check if we have an enemy for this index
    if index and arenaEnemies[index] and arenaEnemies[index].cooldowns[cooldownName] then
        return arenaEnemies[index].cooldowns[cooldownName]
    end
    
    return nil
}

-- Get trinket status
function PvPManager:GetTrinketStatus(unitOrIndex)
    -- Skip if not in PvP
    if not inPvP then
        return nil
    end
    
    -- Convert unit to index if needed
    local index = unitOrIndex
    if type(unitOrIndex) == "string" then
        index = tonumber(string.match(unitOrIndex, "arena(%d)"))
    end
    
    -- Check if we have an enemy for this index
    if index and arenaEnemies[index] then
        return {
            used = arenaEnemies[index].trinketUsed,
            cooldown = arenaEnemies[index].trinketCooldown,
            timestamp = arenaEnemies[index].trinketTime
        }
    end
    
    return nil
}

-- Get priority target
function PvPManager:GetPriorityTarget()
    -- Skip if not in PvP
    if not inPvP then
        return nil
    end
    
    -- Find highest priority target
    local highestPriority = 0
    local highestPriorityEnemy = nil
    
    for _, enemy in ipairs(arenaEnemies) do
        if enemy.priority > highestPriority then
            highestPriority = enemy.priority
            highestPriorityEnemy = enemy
        end
    end
    
    return highestPriorityEnemy
}

-- In PvP zone
function PvPManager:InPvPZone()
    return inPvP
end

-- In arena
function PvPManager:InArena()
    return inArena
end

-- In battleground
function PvPManager:InBattleground()
    return inBattleground
end

-- Toggle enabled state
function PvPManager:Toggle()
    isEnabled = not isEnabled
    
    if isEnabled then
        API.PrintMessage("PvP Manager enabled")
        
        -- Update PvP state
        self:UpdatePvPState()
    else
        API.PrintMessage("PvP Manager disabled")
    end
    
    return isEnabled
}

-- Is enabled
function PvPManager:IsEnabled()
    return isEnabled
end

-- Get arena enemies
function PvPManager:GetArenaEnemies()
    return arenaEnemies
end

-- Get enemy team
function PvPManager:GetEnemyTeam()
    return enemyTeam
end

-- Get friendly team
function PvPManager:GetFriendlyTeam()
    return friendlyTeam
end

-- Get arena type
function PvPManager:GetArenaType()
    return arenaType
end

-- Get PvP combat metrics
function PvPManager:GetPvPCombatMetrics()
    return pvpCombatMetrics
end

-- Return the module
return PvPManager