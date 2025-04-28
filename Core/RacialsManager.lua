-- RacialsManager.lua
-- Handles racial ability usage
local addonName, WR = ...
local RacialsManager = {}
WR.RacialsManager = RacialsManager

-- Dependencies
local API = WR.API
local ErrorHandler = WR.ErrorHandler
local ConfigRegistry = WR.ConfigRegistry

-- Local state
local enableRacialUsage = true
local raceInfo = nil
local racialAbilities = {}
local lastRacialUsed = 0
local MIN_RACIAL_INTERVAL = 1.0  -- Min seconds between racial uses

-- Racial ability mappings by race
local racialAbilityMap = {
    -- Alliance
    ["Human"] = {
        {id = 59752, name = "Will to Survive", type = "defensive", cooldown = 180},
        {id = 20598, name = "The Human Spirit", type = "passive"},
        {id = 20864, name = "Diplomacy", type = "passive"}
    },
    ["Dwarf"] = {
        {id = 20594, name = "Stoneform", type = "defensive", cooldown = 120},
        {id = 59224, name = "Might of the Mountain", type = "passive"},
        {id = 92682, name = "Explorer", type = "passive"}
    },
    ["NightElf"] = {
        {id = 58984, name = "Shadowmeld", type = "utility", cooldown = 120},
        {id = 20582, name = "Quickness", type = "passive"},
        {id = 20585, name = "Wisp Spirit", type = "passive"},
        {id = 21009, name = "Elusiveness", type = "passive"}
    },
    ["Gnome"] = {
        {id = 20589, name = "Escape Artist", type = "utility", cooldown = 60},
        {id = 92680, name = "Nimble Fingers", type = "passive"},
        {id = 20591, name = "Expansive Mind", type = "passive"}
    },
    ["Draenei"] = {
        {id = 59548, name = "Gift of the Naaru", type = "heal", cooldown = 180},
        {id = 28875, name = "Gemcutting", type = "passive"}
    },
    ["Worgen"] = {
        {id = 68992, name = "Darkflight", type = "utility", cooldown = 120},
        {id = 87840, name = "Running Wild", type = "passive"},
        {id = 68996, name = "Two Forms", type = "utility"},
        {id = 68975, name = "Aberration", type = "passive"},
        {id = 68978, name = "Flayer", type = "passive"},
        {id = 94293, name = "Viciousness", type = "passive"}
    },
    ["VoidElf"] = {
        {id = 256948, name = "Spatial Rift", type = "utility", cooldown = 180},
        {id = 255669, name = "Entropic Embrace", type = "passive"},
        {id = 255668, name = "Preternatural Calm", type = "passive"},
        {id = 255664, name = "Ethereal Connection", type = "passive"}
    },
    ["LightforgedDraenei"] = {
        {id = 255647, name = "Light's Judgment", type = "offensive", cooldown = 150},
        {id = 255651, name = "Light's Reckoning", type = "passive"},
        {id = 255650, name = "Holy Resistance", type = "passive"},
        {id = 255649, name = "Forge of Light", type = "utility"}
    },
    ["DarkIronDwarf"] = {
        {id = 265221, name = "Fireblood", type = "offensive", cooldown = 120},
        {id = 265223, name = "Mole Machine", type = "utility", cooldown = 30},
        {id = 265222, name = "Mass Production", type = "passive"},
        {id = 265224, name = "Dungeon Delver", type = "passive"},
        {id = 265225, name = "Forged in Flames", type = "passive"}
    },
    ["KulTiran"] = {
        {id = 287712, name = "Haymaker", type = "offensive", cooldown = 150},
        {id = 291622, name = "Brush It Off", type = "passive"},
        {id = 291442, name = "Jack of All Trades", type = "passive"},
        {id = 291417, name = "Child of the Sea", type = "passive"},
        {id = 291478, name = "Rime of the Ancient Mariner", type = "passive"}
    },
    ["Mechagnome"] = {
        {id = 312924, name = "Hyper Organic Light Originator", type = "utility", cooldown = 90},
        {id = 312923, name = "Combat Analysis", type = "passive"},
        {id = 294527, name = "Mastercraft", type = "passive"},
        {id = 312916, name = "Emergency Failsafe", type = "passive"},
        {id = 312890, name = "Skeleton Pinkie", type = "passive"}
    },

    -- Horde
    ["Orc"] = {
        {id = 20572, name = "Blood Fury", type = "offensive", cooldown = 120},
        {id = 20573, name = "Hardiness", type = "passive"},
        {id = 20574, name = "Axe Specialization", type = "passive"}
    },
    ["Undead"] = {
        {id = 7744, name = "Will of the Forsaken", type = "defensive", cooldown = 120},
        {id = 20577, name = "Cannibalize", type = "heal", cooldown = 120},
        {id = 5227, name = "Underwater Breathing", type = "passive"},
        {id = 20579, name = "Shadow Resistance", type = "passive"}
    },
    ["Tauren"] = {
        {id = 20549, name = "War Stomp", type = "offensive", cooldown = 90},
        {id = 20550, name = "Endurance", type = "passive"},
        {id = 20551, name = "Nature Resistance", type = "passive"},
        {id = 20552, name = "Cultivation", type = "passive"}
    },
    ["Troll"] = {
        {id = 26297, name = "Berserking", type = "offensive", cooldown = 180},
        {id = 20557, name = "Beast Slaying", type = "passive"},
        {id = 20558, name = "Throwing Specialization", type = "passive"},
        {id = 58943, name = "Da Voodoo Shuffle", type = "passive"},
        {id = 26290, name = "Regeneration", type = "passive"}
    },
    ["BloodElf"] = {
        {id = 28730, name = "Arcane Torrent", type = "offensive", cooldown = 90},
        {id = 92682, name = "Explorer", type = "passive"},
        {id = 822, name = "Arcane Resistance", type = "passive"},
        {id = 28877, name = "Arcane Affinity", type = "passive"}
    },
    ["Goblin"] = {
        {id = 69041, name = "Rocket Jump", type = "utility", cooldown = 90},
        {id = 69042, name = "Rocket Barrage", type = "offensive", cooldown = 120},
        {id = 69044, name = "Pack Hobgoblin", type = "utility"},
        {id = 69045, name = "Time is Money", type = "passive"},
        {id = 69046, name = "Better Living Through Chemistry", type = "passive"}
    },
    ["Nightborne"] = {
        {id = 260364, name = "Arcane Pulse", type = "offensive", cooldown = 180},
        {id = 255665, name = "Cantrips", type = "passive"},
        {id = 255661, name = "Magical Affinity", type = "passive"},
        {id = 255662, name = "Ancient History", type = "passive"}
    },
    ["HighmountainTauren"] = {
        {id = 255654, name = "Bull Rush", type = "offensive", cooldown = 120},
        {id = 255655, name = "Pride of Ironhorn", type = "passive"},
        {id = 255656, name = "Mountaineer", type = "passive"},
        {id = 255658, name = "Rugged Tenacity", type = "passive"}
    },
    ["MagharOrc"] = {
        {id = 274738, name = "Ancestral Call", type = "offensive", cooldown = 120},
        {id = 273216, name = "Open Skies", type = "passive"},
        {id = 273217, name = "Savage Blood", type = "passive"},
        {id = 273220, name = "Sympathetic Vigor", type = "passive"}
    },
    ["ZandalariTroll"] = {
        {id = 291944, name = "Regeneratin'", type = "heal", cooldown = 120},
        {id = 291642, name = "Pterrordax Swoop", type = "utility", cooldown = 90},
        {id = 291641, name = "Embrace of the Loa", type = "passive"},
        {id = 292750, name = "City of Gold", type = "passive"}
    },
    ["Vulpera"] = {
        {id = 312411, name = "Bag of Tricks", type = "offensive", cooldown = 90},
        {id = 312370, name = "Make Camp", type = "utility", cooldown = 30},
        {id = 312425, name = "Rummage Your Bag", type = "utility", cooldown = 270},
        {id = 312419, name = "Alpaca Saddlebags", type = "passive"},
        {id = 312198, name = "Nose For Trouble", type = "passive"}
    },

    -- Neutral
    ["Pandaren"] = {
        {id = 107079, name = "Quaking Palm", type = "offensive", cooldown = 120},
        {id = 107072, name = "Epicurean", type = "passive"},
        {id = 107073, name = "Gourmand", type = "passive"},
        {id = 107074, name = "Inner Peace", type = "passive"},
        {id = 107076, name = "Bouncy", type = "passive"}
    },
    ["Dracthyr"] = {
        {id = 357214, name = "Tail Swipe", type = "offensive", cooldown = 90},
        {id = 357212, name = "Wing Buffet", type = "utility", cooldown = 120},
        {id = 368970, name = "Visage", type = "utility"},
        {id = 359827, name = "Soar", type = "utility", cooldown = 180},
        {id = 384350, name = "Essence Font", type = "passive"}
    }
}

-- Initialize module
function RacialsManager:Initialize()
    -- Register settings
    self:RegisterSettings()
    
    -- Determine player's race
    local _, race = UnitRace("player")
    raceInfo = race
    
    -- Get racial abilities for this race
    local racials = racialAbilityMap[race]
    if racials then
        for _, racial in ipairs(racials) do
            -- Check if the racial is known (could vary based on character options)
            if racial.id and API.IsSpellKnown(racial.id) then
                table.insert(racialAbilities, racial)
            end
        end
    end
    
    API.PrintDebug("Racials Manager initialized for race: " .. (race or "Unknown"))
    return true
end

-- Register settings
function RacialsManager:RegisterSettings()
    ConfigRegistry:RegisterSettings("RacialsManager", {
        racialSettings = {
            enableRacialUsage = {
                displayName = "Use Racial Abilities",
                description = "Automatically use racial abilities",
                type = "toggle",
                default = true
            },
            useOffensiveRacials = {
                displayName = "Offensive Racials",
                description = "Use offensive racial abilities",
                type = "toggle",
                default = true
            },
            useDefensiveRacials = {
                displayName = "Defensive Racials",
                description = "Use defensive racial abilities",
                type = "toggle",
                default = true
            },
            useHealingRacials = {
                displayName = "Healing Racials",
                description = "Use healing racial abilities",
                type = "toggle",
                default = true
            },
            useUtilityRacials = {
                displayName = "Utility Racials",
                description = "Use utility racial abilities",
                type = "toggle",
                default = false
            },
            saveOffensiveForCooldowns = {
                displayName = "Save for Cooldowns",
                description = "Save offensive racials for cooldown phases",
                type = "toggle",
                default = true
            },
            defensiveHealthThreshold = {
                displayName = "Defensive Health Threshold",
                description = "Health % to use defensive racials",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 50
            },
            healingHealthThreshold = {
                displayName = "Healing Health Threshold",
                description = "Health % to use healing racials",
                type = "slider",
                min = 10,
                max = 80,
                step = 5,
                default = 40
            }
        }
    })
    
    -- Add callback for settings changes
    ConfigRegistry:RegisterCallback("RacialsManager", function(settings)
        self:ApplySettings(settings)
    end)
end

-- Apply settings
function RacialsManager:ApplySettings(settings)
    -- Apply racial settings
    enableRacialUsage = settings.racialSettings.enableRacialUsage
    useOffensiveRacials = settings.racialSettings.useOffensiveRacials
    useDefensiveRacials = settings.racialSettings.useDefensiveRacials
    useHealingRacials = settings.racialSettings.useHealingRacials
    useUtilityRacials = settings.racialSettings.useUtilityRacials
    saveOffensiveForCooldowns = settings.racialSettings.saveOffensiveForCooldowns
    defensiveHealthThreshold = settings.racialSettings.defensiveHealthThreshold
    healingHealthThreshold = settings.racialSettings.healingHealthThreshold
    
    API.PrintDebug("Racials Manager settings applied")
end

-- Update settings from external source
function RacialsManager.UpdateSettings(newSettings)
    -- This is called from RotationManager
    if newSettings.enableRacialUsage ~= nil then
        enableRacialUsage = newSettings.enableRacialUsage
    end
end

-- Get a list of available racial abilities of a specific type
function RacialsManager:GetAvailableRacials(racialType)
    local available = {}
    
    for _, racial in ipairs(racialAbilities) do
        if racialType == nil or racial.type == racialType then
            -- Check if it's a spell (not passive) and is usable
            if racial.id and racial.type ~= "passive" and API.IsSpellUsable(racial.id) then
                table.insert(available, racial)
            end
        end
    end
    
    return available
end

-- Check if a racial is on cooldown
function RacialsManager:IsRacialOnCooldown(racialId)
    if not racialId then return true end
    
    local start, duration = GetSpellCooldown(racialId)
    if start and duration and start > 0 then
        return true
    end
    
    return false
end

-- Process racials based on combat state
function RacialsManager.ProcessRacials(combatState)
    -- Skip if disabled
    if not enableRacialUsage then
        return nil
    end
    
    -- Skip if we recently used a racial
    if GetTime() - lastRacialUsed < MIN_RACIAL_INTERVAL then
        return nil
    end
    
    -- Get settings safely
    local settings = ConfigRegistry.GetSettings("RacialsManager") or { racialSettings = {} }
    local useOffensiveRacials = settings.racialSettings.useOffensiveRacials
    local useDefensiveRacials = settings.racialSettings.useDefensiveRacials
    local useHealingRacials = settings.racialSettings.useHealingRacials
    local saveOffensiveForCooldowns = settings.racialSettings.saveOffensiveForCooldowns
    local defensiveHealthThreshold = settings.racialSettings.defensiveHealthThreshold or 50
    local healingHealthThreshold = settings.racialSettings.healingHealthThreshold or 40
    
    -- Priority: Healing > Defensive > Offensive > Utility
    local selectedRacial = nil
    
    -- Check for healing racials if health is low
    if useHealingRacials and combatState.health <= healingHealthThreshold then
        local healingRacials = RacialsManager:GetAvailableRacials("heal")
        if #healingRacials > 0 then
            selectedRacial = healingRacials[1]
        end
    end
    
    -- Check for defensive racials if health is low
    if not selectedRacial and useDefensiveRacials and combatState.health <= defensiveHealthThreshold then
        local defensiveRacials = RacialsManager:GetAvailableRacials("defensive")
        if #defensiveRacials > 0 then
            selectedRacial = defensiveRacials[1]
        end
    end
    
    -- Check for offensive racials during burst window or execute phase
    if not selectedRacial and useOffensiveRacials then
        if (not saveOffensiveForCooldowns) or combatState.burstWindow or combatState.executePhase then
            local offensiveRacials = RacialsManager:GetAvailableRacials("offensive")
            if #offensiveRacials > 0 then
                selectedRacial = offensiveRacials[1]
            end
        end
    end
    
    -- If we selected a racial, use it
    if selectedRacial then
        lastRacialUsed = GetTime()
        
        -- Determine the target based on the racial type
        local target = "player"
        if selectedRacial.type == "offensive" then
            target = "target"
        end
        
        return {
            id = selectedRacial.id,
            target = target
        }
    end
    
    return nil
end

-- Return module
return RacialsManager